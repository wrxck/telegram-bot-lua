-- coverage tests for src/main.lua: api.configure, the json/multipart request
-- plumbing, the getMe-family endpoint wrappers and the api._with_retry policy.
local api = require('spec.test_helper')
local json = require('dkjson')

describe('main.lua coverage', function()
    describe('api.configure', function()
        local original_get_me, original_token, original_info, original_debug

        before_each(function()
            original_get_me = api.get_me
            original_token = api.token
            original_info = api.info
            original_debug = api.debug
            api._clear_requests()
        end)

        after_each(function()
            api.get_me = original_get_me
            api.token = original_token
            api.info = original_info
            api.debug = original_debug
        end)

        it('errors when no token is given', function()
            assert.has_error(function()
                api.configure(nil)
            end, 'Please specify your bot API token you received from @BotFather!')
        end)

        it('rejects a non-string token', function()
            assert.has_error(function()
                api.configure(12345)
            end, 'Please specify your bot API token you received from @BotFather!')
        end)

        it('fetches bot info via get_me and unwraps the result', function()
            api.get_me = function()
                return { ok = true, result = {
                    id = 42, first_name = 'CfgBot', username = 'cfg_bot', is_bot = true
                } }, 200
            end
            local returned = api.configure('123:ABC')
            assert.equals(api, returned)
            assert.equals('123:ABC', api.token)
            assert.equals(42, api.info.id)
            assert.equals('CfgBot', api.info.first_name)
            -- info.name is populated from first_name
            assert.equals('CfgBot', api.info.name)
            assert.is_false(api.debug)
        end)

        it('coerces the debug flag to a boolean true', function()
            api.get_me = function()
                return { ok = true, result = { id = 1, first_name = 'D' } }, 200
            end
            api.configure('123:ABC', 'yes')
            assert.is_true(api.debug)
        end)

        it('breaks out of the retry loop under _TEST when get_me fails', function()
            local calls = 0
            api.get_me = function()
                calls = calls + 1
                return false, 'connection refused'
            end
            local returned = api.configure('123:ABC')
            -- with _G._TEST set the loop must not retry or raise
            assert.equals(1, calls)
            assert.equals(api, returned)
            assert.is_false(api.info)
        end)

        it('raises after max retries when get_me keeps failing (non-test mode)', function()
            local calls = 0
            api.get_me = function()
                calls = calls + 1
                return false, 'connection refused'
            end
            local original_execute = os.execute
            local sleeps = 0
            os.execute = function() sleeps = sleeps + 1 return true end
            _G._TEST = false
            finally(function()
                _G._TEST = true
                os.execute = original_execute
            end)
            local ok, err = pcall(api.configure, '123:ABC')
            assert.is_false(ok)
            assert.truthy(tostring(err):find('Failed to connect to Telegram API after 5 attempts'))
            assert.equals(5, calls)
            -- slept between attempts, but not after the final one
            assert.equals(4, sleeps)
        end)
    end)

    describe('api._json_decode', function()
        it('decodes valid JSON', function()
            local decoded = api._json_decode('{"a":1,"b":[2,3]}')
            assert.equals(1, decoded.a)
            assert.same({ 2, 3 }, decoded.b)
        end)

        it('returns nil when dkjson raises (empty string)', function()
            assert.is_nil(api._json_decode(''))
        end)

        it('returns nil for garbage input', function()
            assert.is_nil(api._json_decode('{{{'))
        end)
    end)

    describe('api._build_request_params', function()
        local original_debug

        before_each(function()
            original_debug = api.debug
        end)

        after_each(function()
            api.debug = original_debug
        end)

        it('returns the empty-body sentinel when there are no parameters', function()
            assert.same({ '' }, api._build_request_params(nil))
            assert.same({ '' }, api._build_request_params({}))
        end)

        it('stringifies scalar parameters without mutating the input', function()
            local input = { chat_id = 123, silent = true }
            local params = api._build_request_params(input)
            assert.equals('123', params.chat_id)
            assert.equals('true', params.silent)
            -- caller's table is untouched
            assert.equals(123, input.chat_id)
            assert.equals(true, input.silent)
        end)

        it('prints the parameters when api.debug is on', function()
            api.debug = true
            local printed = {}
            local original_print = print
            _G.print = function(...) table.insert(printed, (...)) end
            finally(function() _G.print = original_print end)
            api._build_request_params({ chat_id = 55, text = 'dbg' })
            assert.equals(1, #printed)
            local dumped = json.decode(printed[1])
            assert.equals('55', dumped.chat_id)
            assert.equals('dbg', dumped.text)
        end)

        it('loads a real file from disk into filename/data form', function()
            local dir = os.getenv('TMPDIR') or '/tmp'
            local path = dir .. '/tbl_coverage_upload.txt'
            local f = assert(io.open(path, 'wb'))
            f:write('file payload bytes')
            f:close()
            finally(function() os.remove(path) end)
            local params = api._build_request_params({ chat_id = 1 }, { document = path })
            assert.is_table(params.document)
            assert.equals(path, params.document.filename)
            assert.equals('file payload bytes', params.document.data)
        end)

        it('passes a non-existent path through as a file_id/URL string', function()
            local params = api._build_request_params({}, { photo = 'AgADBAAD_file_id' })
            assert.equals('AgADBAAD_file_id', params.photo)
        end)

        it('passes a non-string file part through untouched', function()
            local part = { filename = 'x.bin', data = 'raw' }
            local params = api._build_request_params({}, { document = part })
            assert.equals(part, params.document)
        end)
    end)

    describe('api._parse_api_response', function()
        local original_debug

        before_each(function()
            original_debug = api.debug
        end)

        after_each(function()
            api.debug = original_debug
        end)

        it('returns the decoded table and the http status on success', function()
            local jdat, res = api._parse_api_response('{"ok":true,"result":7}', 200)
            assert.equals(7, jdat.result)
            assert.equals(200, res)
        end)

        it('returns (false, jdat) for an API-level error', function()
            local ok, err = api._parse_api_response(
                '{"ok":false,"description":"Bad Request: chat not found","error_code":400}', 200)
            assert.is_false(ok)
            assert.equals(400, err.error_code)
        end)

        it('prints the description and error code when api.debug is on', function()
            api.debug = true
            local printed = {}
            local original_print = print
            _G.print = function(...) table.insert(printed, (...)) end
            finally(function() _G.print = original_print end)
            local ok, err = api._parse_api_response(
                '{"ok":false,"description":"Bad Request: chat not found","error_code":400}', 200)
            assert.is_false(ok)
            assert.equals('Bad Request: chat not found', err.description)
            assert.equals(1, #printed)
            assert.truthy(printed[1]:find('Bad Request: chat not found', 1, true))
            assert.truthy(printed[1]:find('[400]', 1, true))
        end)
    end)

    describe('endpoint wrappers', function()
        before_each(function()
            api._clear_requests()
        end)

        it('get_me hits /getMe on the configured token', function()
            local success, res = api.get_me()
            assert.is_true(success.ok)
            assert.equals(200, res)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('https://api.telegram.org/bottest:TOKEN/getMe', 1, true))
        end)

        it('log_out hits /logOut', function()
            local success = api.log_out()
            assert.is_true(success.ok)
            assert.truthy(api._last_request().endpoint:find('test:TOKEN/logOut', 1, true))
        end)

        it('close hits /close', function()
            local success = api.close()
            assert.is_true(success.ok)
            assert.truthy(api._last_request().endpoint:find('test:TOKEN/close', 1, true))
        end)
    end)

    describe('api._blocking_sleep', function()
        it('sleeps for roughly the requested duration', function()
            local socket = require('socket')
            local before = socket.gettime()
            api._blocking_sleep(0.05)
            local elapsed = socket.gettime() - before
            assert.truthy(elapsed >= 0.04, 'expected at least ~50ms of sleep, got ' .. elapsed)
        end)

        it('falls back to shelling out when socket.sleep is unavailable', function()
            local original_require = _G.require
            local original_execute = os.execute
            local commands = {}
            _G.require = function(name)
                if name == 'socket' then
                    return {} -- a socket module without .sleep
                end
                return original_require(name)
            end
            os.execute = function(cmd)
                table.insert(commands, cmd)
                return true
            end
            finally(function()
                _G.require = original_require
                os.execute = original_execute
            end)
            api._blocking_sleep(2.7)
            -- rounded down but never below 1 second
            assert.same({ 'sleep 2' }, commands)
        end)
    end)

    describe('api._request_core connection-failure branch', function()
        it('returns (false, err) when the http client fails without raising', function()
            local logged = {}
            local result, err = api._request_core(function()
                return nil, 'connection refused'
            end, function(e) table.insert(logged, e) end, 'https://example.invalid/x', { a = 1 })
            assert.is_false(result)
            assert.equals('connection refused', err)
            assert.same({ 'connection refused' }, logged)
        end)
    end)

    describe('api.request retry wiring', function()
        it('routes requests through _with_retry and _http_request', function()
            -- the shared test harness replaces api.request with a recording
            -- mock, so exercise the real function on a fresh module instance.
            local fresh = dofile('src/main.lua')
            local calls = {}
            fresh._http_request = function(endpoint, parameters, file)
                table.insert(calls, { endpoint = endpoint, parameters = parameters, file = file })
                return { ok = true, result = 'fresh' }, 200
            end
            local result, res = fresh.request('https://example.invalid/method', { a = 1 }, { photo = 'p' })
            assert.equals('fresh', result.result)
            assert.equals(200, res)
            assert.equals(1, #calls)
            assert.equals('https://example.invalid/method', calls[1].endpoint)
            assert.same({ a = 1 }, calls[1].parameters)
            assert.same({ photo = 'p' }, calls[1].file)
        end)
    end)

    describe('api._with_retry', function()
        local original_retry
        local sleeps, sleeper

        before_each(function()
            original_retry = {}
            for k, v in pairs(api.retry) do original_retry[k] = v end
            sleeps = {}
            sleeper = function(s) table.insert(sleeps, s) end
        end)

        after_each(function()
            for k, v in pairs(original_retry) do api.retry[k] = v end
            api.retry.enabled = original_retry.enabled
        end)

        it('returns the thunk result untouched on first-try success', function()
            local result, err = api._with_retry(function()
                return { ok = true, result = 1 }, 200
            end, sleeper)
            assert.is_true(result.ok)
            assert.equals(200, err)
            assert.equals(0, #sleeps)
        end)

        it('calls the thunk exactly once when retries are disabled', function()
            api.retry.enabled = false
            local calls = 0
            local result, err = api._with_retry(function()
                calls = calls + 1
                return false, 'connection refused'
            end, sleeper)
            assert.is_false(result)
            assert.equals('connection refused', err)
            assert.equals(1, calls)
            assert.equals(0, #sleeps)
        end)

        it('honours retry_after on a 429 rate limit', function()
            local calls = 0
            local result = api._with_retry(function()
                calls = calls + 1
                if calls == 1 then
                    return false, { error_code = 429, parameters = { retry_after = 7 } }
                end
                return { ok = true }, 200
            end, sleeper)
            assert.is_true(result.ok)
            assert.equals(2, calls)
            assert.same({ 7 }, sleeps)
        end)

        it('falls back to the base delay on a 429 without retry_after', function()
            local calls = 0
            api.retry.base_delay = 3
            local result = api._with_retry(function()
                calls = calls + 1
                if calls == 1 then
                    return false, { error_code = 429 }
                end
                return { ok = true }, 200
            end, sleeper)
            assert.is_true(result.ok)
            assert.same({ 3 }, sleeps)
        end)

        it('returns a fatal API error immediately without sleeping', function()
            local calls = 0
            local result, err = api._with_retry(function()
                calls = calls + 1
                return false, { error_code = 400, description = 'Bad Request' }
            end, sleeper)
            assert.is_false(result)
            assert.equals(400, err.error_code)
            assert.equals(1, calls)
            assert.equals(0, #sleeps)
        end)

        it('retries transient errors with exponential backoff capped at max_delay', function()
            api.retry.max_attempts = 6
            api.retry.base_delay = 10
            api.retry.max_delay = 15
            local calls = 0
            local result, err = api._with_retry(function()
                calls = calls + 1
                return false, 'timeout'
            end, sleeper)
            assert.is_false(result)
            assert.equals('timeout', err)
            assert.equals(6, calls)
            -- 10, then doubled-but-capped at 15 for every later wait
            assert.same({ 10, 15, 15, 15, 15 }, sleeps)
        end)

        it('succeeds after transient failures and stops sleeping', function()
            local calls = 0
            api.retry.max_attempts = 5
            local result = api._with_retry(function()
                calls = calls + 1
                if calls < 3 then
                    return false, 'connection reset'
                end
                return { ok = true, result = 'finally' }, 200
            end, sleeper)
            assert.equals('finally', result.result)
            assert.equals(3, calls)
            assert.same({ 1, 2 }, sleeps)
        end)

        it('gives up after max_attempts transient failures', function()
            local calls = 0
            local result, err = api._with_retry(function()
                calls = calls + 1
                return false, 'unreachable'
            end, sleeper)
            assert.is_false(result)
            assert.equals('unreachable', err)
            assert.equals(3, calls)
            assert.equals(2, #sleeps)
        end)
    end)
end)
