-- coverage tests for src/adapters/init.lua, src/adapters/db.lua and
-- src/adapters/llm.lua. these target branches not exercised by the
-- existing adapter specs (transport selection, driver fallbacks and
-- error paths). every stub is restored so other specs see the real
-- modules.
local api = require('spec.test_helper')

describe('coverage: adapters registry (init.lua)', function()
    describe('is_async', function()
        it('delegates to copas.running() when it is a function', function()
            -- the installed copas exposes `running` as a boolean; swap in a
            -- stub module whose running is a function to drive that branch.
            local real_copas = package.loaded['copas']
            local called = false
            package.loaded['copas'] = {
                running = function()
                    called = true
                    return true
                end,
            }
            local ok, result = pcall(api.adapters.is_async)
            package.loaded['copas'] = real_copas
            assert.is_true(ok)
            assert.is_true(called)
            assert.is_true(result)
        end)
    end)

    describe('http_request transport selection', function()
        local saved

        -- build a fake transport whose request function records the request
        -- table, optionally feeds the sink, and returns a scripted result.
        local function make_transport(behaviour)
            local transport = { calls = {} }
            transport.request = function(req)
                transport.calls[#transport.calls + 1] = req
                return behaviour(req)
            end
            return transport
        end

        before_each(function()
            saved = {
                ['ssl.https'] = package.loaded['ssl.https'],
                ['socket.http'] = package.loaded['socket.http'],
                ['copas.http'] = package.loaded['copas.http'],
            }
        end)

        after_each(function()
            for name, mod in pairs(saved) do
                package.loaded[name] = mod
            end
        end)

        it('GET over https:// uses ssl.https and drains the sink', function()
            local https = make_transport(function(req)
                req.sink('hello ')
                req.sink('world')
                req.sink(nil)
                return 1, 200, { ['x-served-by'] = 'fake-https' }
            end)
            package.loaded['ssl.https'] = https

            local body, status, headers = api.adapters.http_request('https://example.com/x')
            assert.equals('hello world', body)
            assert.equals(200, status)
            assert.equals('fake-https', headers['x-served-by'])
            assert.equals(1, #https.calls)
            local req = https.calls[1]
            assert.equals('GET', req.method)
            assert.equals('https://example.com/x', req.url)
        end)

        it('POST over http:// uses socket.http and sets Content-Length', function()
            local http = make_transport(function(req)
                req.sink('created')
                req.sink(nil)
                return 1, 201, {}
            end)
            package.loaded['socket.http'] = http

            local payload = 'name=test'
            local body, status = api.adapters.http_request('http://example.com/post', {
                method = 'POST',
                headers = { ['Content-Type'] = 'application/x-www-form-urlencoded' },
                body = payload,
            })
            assert.equals('created', body)
            assert.equals(201, status)
            local req = http.calls[1]
            assert.equals('POST', req.method)
            assert.equals(tostring(#payload), req.headers['Content-Length'])
            assert.equals('application/x-www-form-urlencoded', req.headers['Content-Type'])
            -- the body was wired up as an ltn12 source
            assert.is_function(req.source)
            assert.equals(payload, req.source())
        end)

        it('returns nil, err when the transport fails', function()
            package.loaded['ssl.https'] = make_transport(function()
                return nil, 'connection refused'
            end)
            local body, err = api.adapters.http_request('https://example.com/down')
            assert.is_nil(body)
            assert.equals('connection refused', err)
        end)

        it('uses copas.http inside a copas loop', function()
            local copas_http = make_transport(function(req)
                req.sink('async-body')
                req.sink(nil)
                return 1, 200, {}
            end)
            package.loaded['copas.http'] = copas_http

            local copas = require('copas')
            local body, status
            copas.addthread(function()
                body, status = api.adapters.http_request('https://example.com/async')
            end)
            copas.loop()
            assert.equals('async-body', body)
            assert.equals(200, status)
            assert.equals(1, #copas_http.calls)
            assert.equals('https://example.com/async', copas_http.calls[1].url)
        end)
    end)

    describe('create_socket', function()
        it('returns a raw luasocket tcp socket outside copas', function()
            local sock = api.adapters.create_socket()
            -- luasocket master sockets are userdata, not copas proxy tables
            assert.equals('userdata', type(sock))
            sock:close()
        end)

        it('returns a copas-wrapped socket inside a copas loop', function()
            local copas = require('copas')
            local sock
            copas.addthread(function()
                sock = api.adapters.create_socket()
            end)
            copas.loop()
            -- copas.wrap returns a proxy table around the raw socket
            assert.equals('table', type(sock))
            sock:close()
        end)
    end)
end)

describe('coverage: db adapter (db.lua)', function()
    describe('sqlite driver selection', function()
        local real_lsqlite3

        before_each(function()
            -- force-load the real binding so it can be re-exposed under the
            -- lsqlite3complete name (and restored) even if no earlier spec
            -- has required it yet.
            real_lsqlite3 = require('lsqlite3')
        end)

        after_each(function()
            package.loaded['lsqlite3'] = real_lsqlite3
            package.preload['lsqlite3'] = nil
            package.loaded['lsqlite3complete'] = nil
            package.preload['lsqlite3complete'] = nil
        end)

        it('falls back to lsqlite3complete when lsqlite3 is unavailable', function()
            -- hide lsqlite3 and expose the real library under the
            -- lsqlite3complete name so the fallback require succeeds.
            package.loaded['lsqlite3'] = nil
            package.preload['lsqlite3'] = function() error('hidden for test') end
            package.loaded['lsqlite3complete'] = real_lsqlite3

            local db = api.db.connect({ driver = 'sqlite', path = ':memory:' })
            assert.is_true(db:is_connected())
            db:execute('CREATE TABLE t (v INTEGER)')
            db:execute('INSERT INTO t VALUES (?)', { 7 })
            assert.equals(7, db:query('SELECT v FROM t')[1].v)
            db:close()
        end)

        it('errors when neither sqlite binding is available', function()
            package.loaded['lsqlite3'] = nil
            package.preload['lsqlite3'] = function() error('hidden for test') end
            package.loaded['lsqlite3complete'] = nil
            package.preload['lsqlite3complete'] = function() error('hidden for test') end

            local ok, err = pcall(api.db.connect, { driver = 'sqlite', path = ':memory:' })
            assert.is_false(ok)
            assert.truthy(tostring(err):find('SQLite requires the lsqlite3 library'))
        end)

        it('errors when the database file cannot be opened', function()
            local ok, err = pcall(api.db.connect, {
                driver = 'sqlite',
                path = '/nonexistent-cov-dir/sub/never.db',
            })
            assert.is_false(ok)
            assert.truthy(tostring(err):find('Failed to open SQLite database'))
        end)
    end)

    describe('sqlite statement cache and execution', function()
        local db

        before_each(function()
            db = api.db.connect({ driver = 'sqlite', path = ':memory:' })
        end)

        after_each(function()
            if db then db:close() end
        end)

        it('evicts the whole cache when the statement limit is exceeded', function()
            -- 129 distinct statements: the 129th crosses the 128 limit,
            -- finalising and clearing the cache before being cached itself.
            for i = 1, 129 do
                local rows = db:query('SELECT ' .. i .. ' AS v')
                assert.equals(i, rows[1].v)
            end
            assert.equals(1, db._stmt_cache_count)
            assert.is_nil(db._stmt_cache['SELECT 1 AS v'])
            assert.is_truthy(db._stmt_cache['SELECT 129 AS v'])
            -- an evicted statement is recompiled transparently
            assert.equals(1, db:query('SELECT 1 AS v')[1].v)
        end)

        it('uses clear_bindings on cached statements that support it', function()
            -- the installed lsqlite3 statements have no clear_bindings, so
            -- that branch is only reachable through a stand-in cached entry.
            local sqlite3 = require('lsqlite3')
            local calls = {}
            local fake_stmt = {
                reset = function() calls[#calls + 1] = 'reset' end,
                clear_bindings = function() calls[#calls + 1] = 'clear_bindings' end,
                step = function() return sqlite3.DONE end,
            }
            db._stmt_cache['FAKE CACHED SQL'] = fake_stmt
            db._stmt_cache_count = db._stmt_cache_count + 1

            local ok, changes = db:execute('FAKE CACHED SQL')
            assert.is_true(ok)
            assert.equals(0, changes)
            assert.same({ 'reset', 'clear_bindings', 'reset' }, calls)
            -- drop the fake so close() doesn't try to finalise it for real
            db._stmt_cache['FAKE CACHED SQL'] = nil
            db._stmt_cache_count = db._stmt_cache_count - 1
        end)

        it('execute on a row-returning statement reports success with 0 changes', function()
            local ok, changes = db:execute('SELECT 1')
            assert.is_true(ok)
            assert.equals(0, changes)
        end)

        it('transaction surfaces a COMMIT failure and reports it', function()
            db:execute('CREATE TABLE tx_commit_fail (v INTEGER)')
            -- the callback commits the transaction itself, so the helper's
            -- own COMMIT fails ("no transaction is active") and must be
            -- reported instead of pretending success.
            local ok, err = db:transaction(function(c)
                c:execute('INSERT INTO tx_commit_fail VALUES (1)')
                c:execute('COMMIT')
            end)
            assert.is_false(ok)
            assert.is_string(err)
            -- the callback's own commit persisted the row
            assert.equals(1, #db:query('SELECT * FROM tx_commit_fail'))
        end)
    end)

    describe('postgres driver (stubbed pgmoon)', function()
        local real_pgmoon_loaded

        -- build a scripted pgmoon stub. `script` overrides individual
        -- behaviours; every interaction is recorded for assertions.
        local function make_pg(script)
            script = script or {}
            local pg = {
                queries = {},
                disconnected = false,
                sock = script.sock,
            }
            function pg:connect()
                if script.connect_err then
                    return nil, script.connect_err
                end
                return true
            end
            function pg:disconnect()
                self.disconnected = true
            end
            function pg:escape_literal(v)
                return "'" .. tostring(v):gsub("'", "''") .. "'"
            end
            function pg:query(sql)
                self.queries[#self.queries + 1] = sql
                if script.query then
                    return script.query(sql)
                end
                return {}
            end
            return pg
        end

        local function install(pg)
            package.loaded['pgmoon'] = {
                new = function() return pg end,
            }
        end

        before_each(function()
            real_pgmoon_loaded = package.loaded['pgmoon']
        end)

        after_each(function()
            package.loaded['pgmoon'] = real_pgmoon_loaded
            package.preload['pgmoon'] = nil
        end)

        it('errors when pgmoon is not installed', function()
            package.loaded['pgmoon'] = nil
            package.preload['pgmoon'] = function() error('hidden for test') end
            local ok, err = pcall(api.db.connect, { driver = 'postgres', host = 'x' })
            assert.is_false(ok)
            assert.truthy(tostring(err):find('PostgreSQL requires the pgmoon library'))
        end)

        it('errors when the connection fails', function()
            install(make_pg({ connect_err = 'password authentication failed' }))
            local ok, err = pcall(api.db.connect, { driver = 'postgres', host = 'x' })
            assert.is_false(ok)
            assert.truthy(tostring(err):find('Failed to connect to PostgreSQL'))
            assert.truthy(tostring(err):find('password authentication failed'))
        end)

        it('wraps the pgmoon socket with copas when async', function()
            local raw_sock = require('socket').tcp()
            local pg = make_pg({ sock = raw_sock })
            install(pg)
            local real_is_async = api.adapters.is_async
            api.adapters.is_async = function() return true end
            local ok, db = pcall(api.db.connect, { driver = 'postgres', host = 'x' })
            api.adapters.is_async = real_is_async
            assert.is_true(ok)
            -- the raw userdata socket was replaced by a copas proxy table
            assert.equals('table', type(pg.sock))
            assert.not_equals(raw_sock, pg.sock)
            db:close()
            raw_sock:close()
        end)

        it('execute returns affected_rows on success', function()
            local pg = make_pg({ query = function() return { affected_rows = 3 } end })
            install(pg)
            local db = api.db.connect({ driver = 'pg', host = 'x' })
            local ok, affected = db:execute('DELETE FROM t WHERE v > ?', { 10 })
            assert.is_true(ok)
            assert.equals(3, affected)
            assert.equals('DELETE FROM t WHERE v > 10', pg.queries[1])
            db:close()
        end)

        it('execute and query surface pgmoon errors', function()
            local pg = make_pg({ query = function() return nil, 'syntax error at or near "BOGUS"' end })
            install(pg)
            local db = api.db.connect({ driver = 'postgres', host = 'x' })
            local ok, err = db:execute('BOGUS')
            assert.is_false(ok)
            assert.equals('syntax error at or near "BOGUS"', err)
            local rows, qerr = db:query('BOGUS')
            assert.is_nil(rows)
            assert.equals('syntax error at or near "BOGUS"', qerr)
            db:close()
        end)

        it('query normalises a non-table pgmoon result to an empty table', function()
            local pg = make_pg({ query = function() return true end })
            install(pg)
            local db = api.db.connect({ driver = 'postgres', host = 'x' })
            local rows = db:query('SELECT 1')
            assert.same({}, rows)
            db:close()
        end)

        it('escapes nil, number, boolean and string parameters', function()
            local pg = make_pg()
            install(pg)
            local db = api.db.connect({ driver = 'postgres', host = 'x' })
            db:query('SELECT ?, ?, ?, ?, ?', { nil, 42, true, false, "o'brien" })
            assert.equals("SELECT NULL, 42, TRUE, FALSE, 'o''brien'", pg.queries[1])
            db:close()
        end)

        it('close disconnects once and further closes are no-ops', function()
            local pg = make_pg()
            install(pg)
            local db = api.db.connect({ driver = 'postgres', host = 'x' })
            assert.is_true(db:is_connected())
            db:close()
            assert.is_true(pg.disconnected)
            assert.is_false(db:is_connected())
            -- second close must not blow up on the nil handle
            assert.has_no_error(function() db:close() end)
        end)

        it('transaction commits on success and rolls back on error', function()
            local pg = make_pg()
            install(pg)
            local db = api.db.connect({ driver = 'postgres', host = 'x' })

            local ok = db:transaction(function(c)
                c:execute('INSERT INTO t VALUES (?)', { 1 })
            end)
            assert.is_true(ok)
            assert.same({ 'BEGIN', 'INSERT INTO t VALUES (1)', 'COMMIT' }, pg.queries)

            pg.queries = {}
            local ok2, err = db:transaction(function()
                error('kaboom')
            end)
            assert.is_false(ok2)
            assert.truthy(tostring(err):find('kaboom'))
            assert.same({ 'BEGIN', 'ROLLBACK' }, pg.queries)
            db:close()
        end)
    end)
end)

describe('coverage: llm adapter error paths (llm.lua)', function()
    local real_http_request

    before_each(function()
        real_http_request = api.adapters.http_request
    end)

    after_each(function()
        api.adapters.http_request = real_http_request
    end)

    local function openai()
        return api.llm.new({ provider = 'openai', api_key = 'sk-test' })
    end

    local function anthropic()
        return api.llm.new({ provider = 'anthropic', api_key = 'sk-ant-test' })
    end

    it('retries 5xx responses to exhaustion, then reports the parse failure', function()
        local http_calls, sleeps = 0, {}
        api.adapters.http_request = function()
            http_calls = http_calls + 1
            return 'internal server error', 500
        end
        local result, err = openai():chat(
            {{ role = 'user', content = 'hi' }},
            { _sleeper = function(attempt) sleeps[#sleeps + 1] = attempt end })
        -- 3 attempts (1 + 2 retries), backoff between each pair
        assert.equals(3, http_calls)
        assert.same({ 1, 2 }, sleeps)
        -- the 500 body is not json, so the final result is a parse error
        assert.is_nil(result)
        assert.equals('Failed to parse response JSON', err)
    end)

    it('openai chat errors when no choices are returned', function()
        api.adapters.http_request = function()
            return '{"id": "cmpl-1", "choices": []}', 200
        end
        local result, err = openai():chat({{ role = 'user', content = 'hi' }})
        assert.is_nil(result)
        assert.equals('No response choices returned', err)
    end)

    it('openai embed reports transport failure', function()
        api.adapters.http_request = function()
            return nil, 'timeout'
        end
        local result, err = openai():embed('text')
        assert.is_nil(result)
        assert.equals('HTTP request failed: timeout', err)
    end)

    it('openai embed reports invalid response JSON', function()
        api.adapters.http_request = function()
            return 'this is not json', 200
        end
        local result, err = openai():embed('text')
        assert.is_nil(result)
        assert.equals('Failed to parse response JSON', err)
    end)

    it('openai embed surfaces API error payloads', function()
        api.adapters.http_request = function()
            return '{"error": {"message": "model not found"}}', 200
        end
        local result, err = openai():embed('text')
        assert.is_nil(result)
        assert.equals('model not found', err)
    end)

    it('anthropic chat reports transport failure', function()
        api.adapters.http_request = function()
            return nil, 'connection reset'
        end
        local result, err = anthropic():chat({{ role = 'user', content = 'hi' }})
        assert.is_nil(result)
        assert.equals('HTTP request failed: connection reset', err)
    end)

    it('anthropic chat reports invalid response JSON', function()
        api.adapters.http_request = function()
            return '<html>gateway error</html>', 200
        end
        local result, err = anthropic():chat({{ role = 'user', content = 'hi' }})
        assert.is_nil(result)
        assert.equals('Failed to parse response JSON', err)
    end)
end)
