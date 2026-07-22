-- coverage tests for src/adapters/redis.lua and src/adapters/email.lua.
-- redis tests use the live server on 127.0.0.1:6379 (db 15, keys prefixed
-- 'cov_') plus scripted fake sockets for protocol edge cases. email tests
-- stub socket.smtp.send. all stubs are restored after each test.
local api = require('spec.test_helper')

-- verify the redis server actually answers PING (see adapters_redis_spec).
local function redis_available()
    local socket = require('socket')
    local sock = socket.tcp()
    sock:settimeout(1)
    local ok = sock:connect('127.0.0.1', 6379)
    if not ok then
        sock:close()
        return false
    end
    sock:send('PING\r\n')
    local line = sock:receive('*l')
    sock:close()
    return line ~= nil and line:sub(1, 5) == '+PONG'
end

describe('coverage: redis adapter (redis.lua)', function()
    if redis_available() then
        describe('live server (db 15)', function()
            local redis

            local function cleanup(conn)
                pcall(function()
                    local keys = conn:keys('cov_*')
                    if keys and #keys > 0 then
                        conn:del((table.unpack or unpack)(keys))
                    end
                end)
            end

            before_each(function()
                redis = api.redis.connect({ host = '127.0.0.1', port = 6379, db = 15 })
                cleanup(redis)
            end)

            after_each(function()
                if redis then
                    cleanup(redis)
                    pcall(function() redis:close() end)
                end
            end)

            it('surfaces server error replies as nil, err', function()
                redis:set('cov_str', 'not-a-number')
                local value, err = redis:incr('cov_str')
                assert.is_nil(value)
                assert.truthy(tostring(err):find('not an integer'))
            end)

            it('set with px sets a millisecond TTL', function()
                assert.equals('OK', redis:set('cov_px', 'v', { px = 60000 }))
                local pttl = redis:pttl('cov_px')
                assert.truthy(pttl > 0 and pttl <= 60000)
            end)

            it('mset stores several keys at once', function()
                assert.equals('OK', redis:mset('cov_m1', 'a', 'cov_m2', 'b'))
                assert.equals('a', redis:get('cov_m1'))
                assert.equals('b', redis:get('cov_m2'))
            end)

            it('pexpire applies a millisecond TTL to an existing key', function()
                redis:set('cov_pex', 'v')
                assert.equals(1, redis:pexpire('cov_pex', 60000))
                local pttl = redis:pttl('cov_pex')
                assert.truthy(pttl > 0 and pttl <= 60000)
            end)

            it('hgetall on a non-hash key degrades to an empty table', function()
                redis:set('cov_plain', 'v')
                assert.same({}, redis:hgetall('cov_plain'))
            end)

            it('zrange withscores interleaves members and scores', function()
                redis:zadd('cov_z', 1, 'a')
                redis:zadd('cov_z', 2, 'b')
                local result = redis:zrange('cov_z', 0, -1, true)
                assert.same({ 'a', '1', 'b', '2' }, result)
            end)

            it('info returns server details, optionally filtered by section', function()
                local full = redis:info()
                assert.is_string(full)
                assert.truthy(full:find('redis_version'))
                local server_only = redis:info('server')
                assert.is_string(server_only)
                assert.truthy(server_only:find('redis_version'))
                assert.is_nil(server_only:find('connected_clients'))
            end)

            it('flushdb empties the current (test) database', function()
                redis:set('cov_flush_me', 'v')
                assert.equals('OK', redis:flushdb())
                assert.is_nil(redis:get('cov_flush_me'))
                assert.equals(0, redis:dbsize())
            end)

            it('publish returns the subscriber count', function()
                assert.equals(0, redis:publish('cov_chan', 'hello'))
            end)

            it('commands on a closed connection fail cleanly', function()
                redis:close()
                local value, err = redis:get('cov_whatever')
                assert.is_nil(value)
                assert.equals('Redis connection is closed', err)
                redis = nil
            end)

            it('connect fails when AUTH is rejected', function()
                -- the test server has no password, so AUTH always errors
                local ok, err = pcall(api.redis.connect, {
                    host = '127.0.0.1', port = 6379, password = 'wrong',
                })
                assert.is_false(ok)
                assert.truthy(tostring(err):find('Redis AUTH failed'))
            end)

            it('connect fails when SELECT is rejected', function()
                local ok, err = pcall(api.redis.connect, {
                    host = '127.0.0.1', port = 6379, db = 9999,
                })
                assert.is_false(ok)
                assert.truthy(tostring(err):find('Redis SELECT failed'))
            end)

            it('uses a copas-wrapped socket inside a copas loop', function()
                local copas = require('copas')
                local sock_type, value
                copas.addthread(function()
                    local conn = api.redis.connect({ host = '127.0.0.1', port = 6379, db = 15 })
                    sock_type = type(conn._sock)
                    conn:set('cov_async', 'async-value')
                    value = conn:get('cov_async')
                    conn:del('cov_async')
                    conn:close()
                end)
                copas.loop()
                -- copas.wrap returns a proxy table around the raw socket
                assert.equals('table', sock_type)
                assert.equals('async-value', value)
            end)
        end)
    else
        pending('redis live tests skipped - no Redis server on 127.0.0.1:6379')
    end

    -- protocol edge cases over a scripted fake socket (pattern shared with
    -- adapters_redis_spec.lua): receive() replays a queue of RESP chunks.
    describe('protocol edges (fake socket)', function()
        local socket = require('socket')

        local function make_fake_socket()
            local fake = {
                sent = {},
                _queue = {},
                _pos = 0,
                closed = false,
            }
            function fake:settimeout() end
            function fake:connect() return 1 end
            function fake:send(data)
                if self._fail_send then
                    return nil, 'closed'
                end
                self.sent[#self.sent + 1] = data
                return #data
            end
            function fake:receive()
                if self._fail_recv then
                    return nil, 'closed'
                end
                self._pos = self._pos + 1
                local item = self._queue[self._pos]
                if item == nil then
                    return nil, 'closed'
                end
                if type(item) == 'table' and item.bytes then
                    return item.bytes
                end
                return item
            end
            function fake:close() self.closed = true end
            function fake:enqueue(...)
                for _, v in ipairs({...}) do
                    self._queue[#self._queue + 1] = v
                end
            end
            return fake
        end

        local function with_fake(factory, fn)
            local real_tcp = socket.tcp
            socket.tcp = factory
            local ok, err = pcall(fn)
            socket.tcp = real_tcp
            if not ok then error(err) end
        end

        -- factory that hands out a scripted first socket and makes any
        -- reconnect attempt fail, so transport errors surface unchanged.
        local function single_socket(prime)
            local first
            local count = 0
            return function()
                count = count + 1
                if count == 1 then
                    first = make_fake_socket()
                    if prime then prime(first) end
                    return first
                end
                local dead = make_fake_socket()
                dead.connect = function() return nil, 'refused' end
                return dead
            end, function() return first end
        end

        it('rejects an unknown RESP type prefix', function()
            local factory, get_first = single_socket()
            with_fake(factory, function()
                local conn = api.redis.connect({})
                get_first():enqueue('!bogus')
                local value, err = conn:command('GET', 'k')
                assert.is_nil(value)
                assert.equals('Unknown RESP type: !', err)
            end)
        end)

        it('reports a read failure inside a bulk string body', function()
            local factory, get_first = single_socket()
            with_fake(factory, function()
                local conn = api.redis.connect({})
                -- header promises 5 bytes but the connection dies before the body
                get_first():enqueue('$5')
                local value, err = conn:get('k')
                assert.is_nil(value)
                assert.truthy(tostring(err):find('Redis read error'))
            end)
        end)

        it('returns nil for a null array reply', function()
            local factory, get_first = single_socket()
            with_fake(factory, function()
                local conn = api.redis.connect({})
                get_first():enqueue('*-1')
                local value, err = conn:command('BLPOP', 'k', 0)
                assert.is_nil(value)
                assert.is_nil(err)
            end)
        end)

        it('surfaces a transport failure in the middle of an array', function()
            local factory, get_first = single_socket()
            with_fake(factory, function()
                local conn = api.redis.connect({})
                -- a two-element array whose second element never arrives
                get_first():enqueue('*2', '$1', { bytes = 'a\r\n' })
                local value, err = conn:command('MGET', 'a', 'b')
                assert.is_nil(value)
                assert.truthy(tostring(err):find('Redis read error'))
            end)
        end)

        it('reports a send failure when the reconnect also fails', function()
            local factory, get_first = single_socket(function(fake)
                fake._fail_send = true
            end)
            with_fake(factory, function()
                local conn = api.redis.connect({})
                local value, err = conn:set('k', 'v')
                assert.is_nil(value)
                assert.truthy(tostring(err):find('Redis send error'))
            end)
        end)

        it('fails reconnect when re-authentication is rejected', function()
            local sockets = {}
            local count = 0
            with_fake(function()
                count = count + 1
                local f = make_fake_socket()
                sockets[count] = f
                if count == 1 then
                    f:enqueue('+OK') -- initial AUTH succeeds
                else
                    f:enqueue('-ERR invalid password') -- reconnect AUTH fails
                end
                return f
            end, function()
                local conn = api.redis.connect({ password = 'pw' })
                -- kill the first socket, forcing the reconnect path
                sockets[1]._fail_recv = true
                local value, err = conn:get('k')
                assert.is_nil(value)
                -- the original transport error is reported, not the auth one
                assert.truthy(tostring(err):find('Redis read error'))
                -- the half-authenticated reconnect socket was closed again
                assert.equals(2, count)
                assert.is_true(sockets[2].closed)
            end)
        end)

        it('scan and scan_all propagate a server error reply', function()
            local factory, get_first = single_socket()
            with_fake(factory, function()
                local conn = api.redis.connect({})
                get_first():enqueue('-ERR SCAN is disabled')
                local cursor, err = conn:scan('0')
                assert.is_nil(cursor)
                assert.equals('ERR SCAN is disabled', err)

                get_first():enqueue('-ERR SCAN is disabled')
                local keys, all_err = conn:scan_all('cov_*')
                assert.is_nil(keys)
                assert.equals('ERR SCAN is disabled', all_err)
            end)
        end)
    end)
end)

describe('coverage: email adapter (email.lua)', function()
    local mailer
    local captured_params
    local real_smtp_send

    -- drain the ltn12 source to reconstruct the raw wire message
    local function wire_message()
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
        real_smtp_send = smtp.send
        smtp.send = function(params)
            captured_params = params
            return true
        end
        captured_params = nil
    end)

    after_each(function()
        require('socket.smtp').send = real_smtp_send
    end)

    it('adds a sanitised Reply-To header when requested', function()
        assert.is_true(mailer:send({
            from = 'bot@example.com',
            to = 'user@example.com',
            reply_to = 'noreply@example.com\r\nBcc: evil@example.com',
            subject = 'T',
            body = 'x',
        }))
        local raw = wire_message()
        -- present, and with the CRLF injection flattened to a space
        assert.truthy(raw:find('Reply%-To: noreply@example.com'))
        assert.is_nil(raw:find('\r\nBcc:', 1, true))
    end)

    it('flushes the buffered quoted-printable tail of the body', function()
        -- a body ending in '=' with no trailing newline is only emitted by
        -- the final filter(nil) flush; losing it would truncate the message.
        mailer:send({
            from = 'bot@example.com',
            to = 'user@example.com',
            subject = 'T',
            body = 'balance is 100=',
            html = '<p>ok</p>',
        })
        local raw = wire_message()
        assert.truthy(raw:find('balance is 100=3D', 1, true))
    end)

    it('send_text builds a plain-text message body', function()
        mailer:send_text('bot@example.com', 'user@example.com', 'S', 'plain words')
        local raw = wire_message()
        assert.truthy(raw:find('Content%-Type: text/plain'))
        assert.truthy(raw:find('plain words', 1, true))
        assert.is_nil(raw:find('text/html'))
    end)

    it('send_html builds an html message body', function()
        mailer:send_html('bot@example.com', 'user@example.com', 'S', '<b>rich</b>')
        local raw = wire_message()
        assert.truthy(raw:find('Content%-Type: text/html'))
        assert.truthy(raw:find('<b>rich</b>', 1, true))
    end)

    describe('tls create()', function()
        it('provides a create function returning a raw socket when sync', function()
            local created
            require('socket.smtp').send = function(params)
                if params.create then
                    created = params.create()
                end
                captured_params = params
                return true
            end
            assert.is_true(mailer:send({
                from = 'bot@example.com', to = 'user@example.com',
                subject = 'T', body = 'x',
            }))
            assert.is_function(captured_params.create)
            -- outside copas the socket is the raw luasocket userdata
            assert.equals('userdata', type(created))
            created:close()
        end)

        it('returns a copas-wrapped starttls socket when async', function()
            local real_is_async = api.adapters.is_async
            api.adapters.is_async = function() return true end
            local created
            require('socket.smtp').send = function(params)
                if params.create then
                    created = params.create()
                end
                return true
            end
            local ok, err = pcall(function()
                mailer:send({
                    from = 'bot@example.com', to = 'user@example.com',
                    subject = 'T', body = 'x',
                })
            end)
            api.adapters.is_async = real_is_async
            assert.is_true(ok, tostring(err))
            -- copas.wrap returns a proxy table around the raw socket
            assert.equals('table', type(created))
            created:close()
        end)

        it('warns and skips create() when luasec is unavailable', function()
            local real_ssl = package.loaded['ssl']
            package.loaded['ssl'] = nil
            package.preload['ssl'] = function() error('hidden for test') end
            local warnings = {}
            local real_warn = api.log.warn
            api.log.warn = function(msg) warnings[#warnings + 1] = tostring(msg) end

            local ok, err = pcall(function()
                return mailer:send({
                    from = 'bot@example.com', to = 'user@example.com',
                    subject = 'T', body = 'x',
                })
            end)

            api.log.warn = real_warn
            package.preload['ssl'] = nil
            package.loaded['ssl'] = real_ssl

            assert.is_true(ok, tostring(err))
            assert.equals(1, #warnings)
            assert.truthy(warnings[1]:find('tls requested'))
            -- without luasec no STARTTLS create function is attached
            assert.is_nil(captured_params.create)
        end)
    end)
end)
