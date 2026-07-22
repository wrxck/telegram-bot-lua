-- regression tests for adapter issues found during the quality review.
local api = require('spec.test_helper')

describe('quality review: db adapter (sqlite)', function()
    local db
    before_each(function()
        db = api.db.connect({ driver = 'sqlite', path = ':memory:' })
    end)
    after_each(function()
        if db then db:close() end
    end)

    it('cached statements do not leak stale parameter bindings', function()
        assert.equals(42, db:query('SELECT ? AS v', { 42 })[1].v)
        -- a second call with no params must see NULL, not the stale 42.
        local rows = db:query('SELECT ? AS v')
        assert.is_nil(rows[1].v)
    end)

    it('parameter-count mismatch returns false, err instead of raising', function()
        db:execute('CREATE TABLE t (a, b)')
        local ok, err = db:execute('INSERT INTO t VALUES (?, ?)', { 1 })
        assert.is_false(ok)
        assert.is_string(err)
        -- query path follows the same contract
        local rows, qerr = db:query('SELECT ?, ?', { 1, 2, 3 })
        assert.is_nil(rows)
        assert.is_string(qerr)
    end)

    it('nested transaction does not commit the outer transaction', function()
        db:execute('CREATE TABLE acct (id INTEGER)')
        db:begin()
        db:execute('INSERT INTO acct VALUES (1)')
        -- inner transaction: BEGIN fails (already in a tx) and must abort
        -- rather than silently committing the outer transaction.
        local ok, err = db:transaction(function(c)
            c:execute('INSERT INTO acct VALUES (2)')
        end)
        assert.is_false(ok)
        assert.is_string(err)
        -- the outer transaction is still open and can be rolled back.
        assert.is_true((db:rollback()))
        assert.equals(0, #db:query('SELECT * FROM acct'))
    end)

    it('transaction still commits on success', function()
        db:execute('CREATE TABLE t (a)')
        local ok = db:transaction(function(c)
            c:execute('INSERT INTO t VALUES (1)')
        end)
        assert.is_true(ok)
        assert.equals(1, #db:query('SELECT * FROM t'))
    end)

    it('transaction still rolls back on handler error', function()
        db:execute('CREATE TABLE t (a)')
        local ok, err = db:transaction(function(c)
            c:execute('INSERT INTO t VALUES (1)')
            error('boom')
        end)
        assert.is_false(ok)
        assert.truthy(tostring(err):find('boom'))
        assert.equals(0, #db:query('SELECT * FROM t'))
    end)
end)

describe('quality review: db adapter (postgres interpolation)', function()
    local captured
    local stub_pg = {
        escape_literal = function(_, v) return "'" .. tostring(v):gsub("'", "''") .. "'" end,
        query = function(_, sql) captured = sql return {} end,
        connect = function() return true end,
        disconnect = function() end,
    }
    local db

    setup(function()
        package.loaded['pgmoon'] = {
            new = function() return stub_pg end
        }
        db = api.db.connect({ driver = 'postgres', host = 'x', database = 'd' })
    end)

    teardown(function()
        package.loaded['pgmoon'] = nil
    end)

    before_each(function()
        captured = nil
    end)

    it('does not rewrite ? placeholders inside string literals', function()
        db:query("SELECT * FROM msgs WHERE body = 'why?' AND id = ?", { 7 })
        assert.equals("SELECT * FROM msgs WHERE body = 'why?' AND id = 7", captured)
    end)

    it('honours doubled-quote escapes inside literals', function()
        db:query("SELECT 'it''s a ?' AS s, ? AS v", { 5 })
        assert.equals("SELECT 'it''s a ?' AS s, 5 AS v", captured)
    end)

    it('errors on missing parameters instead of silently sending NULL', function()
        local rows, err = db:query('SELECT * FROM t WHERE a = ? AND b = ?', { 1 })
        assert.is_nil(rows)
        assert.is_string(err)
        assert.is_nil(captured)
        local ok, err2 = db:execute('INSERT INTO t VALUES (?, ?)', { 1 })
        assert.is_false(ok)
        assert.is_string(err2)
    end)

    it('still escapes string parameters', function()
        db:query('SELECT ? AS v', { "o'brien" })
        assert.equals("SELECT 'o''brien' AS v", captured)
    end)

    it('leaves sql untouched when no parameters are given', function()
        db:query('SELECT 1')
        assert.equals('SELECT 1', captured)
    end)
end)

describe('quality review: email adapter', function()
    local mailer
    local captured_params
    local original_smtp_send

    local function wire_message()
        -- drain the ltn12 source to reconstruct the raw message
        local chunks = {}
        while true do
            local chunk = captured_params.source()
            if not chunk then break end
            chunks[#chunks + 1] = chunk
        end
        return table.concat(chunks)
    end

    before_each(function()
        mailer = api.email.new({ host = 'smtp.example.com' })
        local smtp = require('socket.smtp')
        original_smtp_send = smtp.send
        smtp.send = function(params)
            captured_params = params
            return true
        end
    end)

    after_each(function()
        require('socket.smtp').send = original_smtp_send
    end)

    it('does not mutate the caller to table and keeps CC out of To:', function()
        local to = { 'user@example.com' }
        mailer:send({
            from = 'bot@example.com', to = to, cc = 'admin@example.com',
            subject = 'T', body = 'x'
        })
        assert.equals(1, #to)
        local raw = wire_message()
        assert.truthy(raw:find('To: user@example.com\r\n', 1, true))
        assert.is_nil(raw:find('To: user@example.com, admin@example.com', 1, true))
        -- CC still reaches the envelope and its own header
        assert.equals(2, #captured_params.rcpt)
        assert.truthy(raw:find('Cc: admin@example.com', 1, true))
    end)

    it('strips CRLF from header values (no header injection)', function()
        mailer:send({
            from = 'bot@example.com', to = 'user@example.com',
            subject = 'Hi\r\nBcc: evil@attacker.example', body = 'x'
        })
        local raw = wire_message()
        -- the injected text must never start a header line of its own
        assert.is_nil(raw:find('\r\nBcc:', 1, true))
        assert.truthy(raw:find('Subject: Hi', 1, true))
    end)

    it('actually quoted-printable encodes parts declared as such', function()
        mailer:send({
            from = 'bot@example.com', to = 'user@example.com',
            subject = 'T', body = 'discount = 50% today', html = '<b>=</b>'
        })
        local raw = wire_message()
        assert.truthy(raw:find('discount =3D 50%', 1, true))
        assert.truthy(raw:find('<b>=3D</b>', 1, true))
    end)

    it('uses content-collision-resistant boundaries', function()
        mailer:send({
            from = 'bot@example.com', to = 'user@example.com',
            subject = 'T', body = '--boundary_mixed\r\nnot a real boundary',
            attachments = { { filename = 'a.txt', content = 'data' } }
        })
        local raw = wire_message()
        local boundary = raw:match('multipart/mixed; boundary="([^"]+)"')
        assert.is_string(boundary)
        assert.is_nil(boundary:find('boundary_mixed', 1, true))
        -- the body content must not match the generated boundary
        assert.is_nil(('--boundary_mixed'):find('--' .. boundary, 1, true))
    end)
end)

describe('quality review: redis adapter', function()
    local function redis_available()
        local socket = require('socket')
        local sock = socket.tcp()
        sock:settimeout(1)
        local ok = sock:connect('127.0.0.1', 6379)
        sock:close()
        return ok ~= nil
    end

    if not redis_available() then
        pending('redis not available on 127.0.0.1:6379', function() end)
        return
    end

    local conn
    before_each(function()
        conn = api.redis.connect({ host = '127.0.0.1', port = 6379, db = 15 })
    end)
    after_each(function()
        if conn then pcall(function() conn:close() end) end
    end)

    it('mget represents missing keys as false, keeping the array well-formed', function()
        conn:set('qr_k1', 'v1')
        conn:set('qr_k3', 'v3')
        conn:command('DEL', 'qr_missing')
        local vals = conn:mget('qr_k1', 'qr_missing', 'qr_k3')
        assert.equals(3, #vals)
        assert.equals('v1', vals[1])
        assert.is_false(vals[2])
        assert.equals('v3', vals[3])
        conn:command('DEL', 'qr_k1', 'qr_k3')
    end)

    it('is_connected returns false on a server-closed socket', function()
        -- QUIT makes the server close the connection; the socket object
        -- still exists client-side.
        conn._sock:send('*1\r\n$4\r\nQUIT\r\n')
        conn._sock:receive('*l')
        assert.is_false(conn:is_connected())
    end)

    it('is_connected returns true on a live connection', function()
        assert.is_true(conn:is_connected())
    end)

    it('command returns exactly two values on the retry path', function()
        conn:set('qr_retry', 'x')
        -- kill the socket server-side, then issue a command: the client
        -- reconnects and retries; the third internal flag must not leak.
        conn._sock:send('*1\r\n$4\r\nQUIT\r\n')
        conn._sock:receive('*l')
        local returns = { conn:command('GET', 'qr_retry') }
        assert.equals('x', returns[1])
        assert.equals(1, #returns)
        conn:command('DEL', 'qr_retry')
    end)
end)
