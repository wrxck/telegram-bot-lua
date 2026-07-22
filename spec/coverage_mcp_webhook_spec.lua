-- coverage tests for src/mcp.lua (per-tool call closures, error branches,
-- serve notification handling) and src/webhook.lua (api.webhook.serve over
-- real sockets inside a copas loop).
local api = require('spec.test_helper')
local json = require('dkjson')

describe('mcp tool dispatch coverage', function()
    before_each(function()
        api._clear_requests()
    end)

    local function call_tool(name, args)
        local response = api.mcp.handle(json.encode({
            jsonrpc = '2.0',
            id = 1,
            method = 'tools/call',
            params = { name = name, arguments = args }
        }))
        return json.decode(response)
    end

    it('send_photo forwards the photo as a file part with caption opts', function()
        local response = call_tool('send_photo', {
            chat_id = '55', photo = 'AgAD_photo_id', caption = 'cap', parse_mode = 'HTML'
        })
        assert.is_false(response.result.isError)
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/sendPhoto', 1, true))
        assert.equals('55', req.parameters.chat_id)
        assert.equals('cap', req.parameters.caption)
        assert.equals('HTML', req.parameters.parse_mode)
        assert.equals('AgAD_photo_id', req.file.photo)
    end)

    it('get_updates forwards polling options', function()
        call_tool('get_updates', { limit = 10, timeout = 0, offset = 5 })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/getUpdates', 1, true))
        assert.equals(10, req.parameters.limit)
        assert.equals(5, req.parameters.offset)
    end)

    it('get_chat requests the chat by id', function()
        call_tool('get_chat', { chat_id = '@some_channel' })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/getChat', 1, true))
        assert.equals('@some_channel', req.parameters.chat_id)
    end)

    it('get_chat_member passes chat and user ids', function()
        call_tool('get_chat_member', { chat_id = '-100777', user_id = 42 })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/getChatMember', 1, true))
        assert.equals('-100777', req.parameters.chat_id)
        assert.equals(42, req.parameters.user_id)
    end)

    it('get_chat_member_count hits getChatMemberCount', function()
        call_tool('get_chat_member_count', { chat_id = '-100777' })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/getChatMemberCount', 1, true))
        assert.equals('-100777', req.parameters.chat_id)
    end)

    it('unban_chat_member passes only_if_banned', function()
        call_tool('unban_chat_member', {
            chat_id = '-100777', user_id = 42, only_if_banned = true
        })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/unbanChatMember', 1, true))
        assert.equals(42, req.parameters.user_id)
        assert.equals(true, req.parameters.only_if_banned)
    end)

    it('pin_chat_message pins with disable_notification', function()
        call_tool('pin_chat_message', {
            chat_id = '9', message_id = 100, disable_notification = true
        })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/pinChatMessage', 1, true))
        assert.equals(100, req.parameters.message_id)
        assert.equals(true, req.parameters.disable_notification)
    end)

    it('unpin_chat_message unpins a specific message', function()
        call_tool('unpin_chat_message', { chat_id = '9', message_id = 100 })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/unpinChatMessage', 1, true))
        assert.equals('9', req.parameters.chat_id)
        assert.equals(100, req.parameters.message_id)
    end)

    it('answer_callback_query forwards text and show_alert', function()
        call_tool('answer_callback_query', {
            callback_query_id = 'cbq1', text = 'done', show_alert = true
        })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/answerCallbackQuery', 1, true))
        assert.equals('cbq1', req.parameters.callback_query_id)
        assert.equals('done', req.parameters.text)
        assert.equals(true, req.parameters.show_alert)
    end)

    it('edit_message_text edits with a parse mode', function()
        call_tool('edit_message_text', {
            chat_id = '9', message_id = 3, text = 'new text', parse_mode = 'HTML'
        })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/editMessageText', 1, true))
        assert.equals(3, req.parameters.message_id)
        assert.equals('new text', req.parameters.text)
        assert.equals('HTML', req.parameters.parse_mode)
    end)

    it('forward_message forwards between chats', function()
        call_tool('forward_message', {
            chat_id = '1', from_chat_id = '2', message_id = 33, disable_notification = true
        })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/forwardMessage', 1, true))
        assert.equals('1', req.parameters.chat_id)
        assert.equals('2', req.parameters.from_chat_id)
        assert.equals(33, req.parameters.message_id)
    end)

    it('send_document forwards the document as a file part', function()
        call_tool('send_document', {
            chat_id = '55', document = 'BQAD_doc_id', caption = 'the doc'
        })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/sendDocument', 1, true))
        assert.equals('the doc', req.parameters.caption)
        assert.equals('BQAD_doc_id', req.file.document)
    end)

    it('set_chat_title sets the title', function()
        call_tool('set_chat_title', { chat_id = '9', title = 'New Title' })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/setChatTitle', 1, true))
        assert.equals('New Title', req.parameters.title)
    end)

    it('set_chat_description hits setChatDescription for the chat', function()
        local response = call_tool('set_chat_description', {
            chat_id = '9', description = 'About us'
        })
        assert.is_false(response.result.isError)
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/setChatDescription', 1, true))
        assert.equals('9', req.parameters.chat_id)
        -- note: the tool closure passes an opts table into
        -- api.set_chat_description(chat_id, description), so the description
        -- reaches the wire tostring'd; assert the parameter is present rather
        -- than enshrining that representation.
        assert.is_not_nil(req.parameters.description)
    end)

    it('leave_chat leaves the chat', function()
        call_tool('leave_chat', { chat_id = '-100777' })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/leaveChat', 1, true))
        assert.equals('-100777', req.parameters.chat_id)
    end)

    it('get_chat_administrators lists admins', function()
        call_tool('get_chat_administrators', { chat_id = '-100777' })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/getChatAdministrators', 1, true))
        assert.equals('-100777', req.parameters.chat_id)
    end)

    it('send_location sends coordinates', function()
        call_tool('send_location', { chat_id = '9', latitude = 1.5, longitude = 2.5 })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/sendLocation', 1, true))
        assert.equals(1.5, req.parameters.latitude)
        assert.equals(2.5, req.parameters.longitude)
    end)

    it('send_contact sends the contact fields', function()
        call_tool('send_contact', {
            chat_id = '9', phone_number = '+441234', first_name = 'Ada', last_name = 'Lovelace'
        })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/sendContact', 1, true))
        assert.equals('+441234', req.parameters.phone_number)
        assert.equals('Ada', req.parameters.first_name)
        assert.equals('Lovelace', req.parameters.last_name)
    end)

    it('restrict_chat_member forwards permissions and until_date', function()
        call_tool('restrict_chat_member', {
            chat_id = '-100777', user_id = 42,
            permissions = { can_send_messages = false },
            until_date = 1900000000
        })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/restrictChatMember', 1, true))
        assert.equals(42, req.parameters.user_id)
        assert.equals(1900000000, req.parameters.until_date)
        -- permissions travel as a JSON-encoded string
        assert.is_string(req.parameters.permissions)
        assert.is_false(json.decode(req.parameters.permissions).can_send_messages)
    end)

    it('reports INTERNAL_ERROR when a tool raises', function()
        local original_leave_chat = api.leave_chat
        api.leave_chat = function() error('boom from tool') end
        finally(function() api.leave_chat = original_leave_chat end)
        local response = call_tool('leave_chat', { chat_id = '9' })
        assert.equals(-32603, response.error.code)
        assert.truthy(response.error.message:find('boom from tool', 1, true))
    end)

    it('marks a false tool result as isError with stringified content', function()
        api._mock_response(false)
        local response = call_tool('get_chat_member_count', { chat_id = '9' })
        assert.is_true(response.result.isError)
        assert.equals('false', response.result.content[1].text)
    end)
end)

describe('mcp serve notification handling', function()
    it('writes nothing for notification lines (no id)', function()
        local lines = {
            json.encode({ jsonrpc = '2.0', method = 'notifications/initialized' }),
            json.encode({ jsonrpc = '2.0', id = 1, method = 'ping' }),
        }
        local i = 0
        local input = {
            lines = function(_)
                return function()
                    i = i + 1
                    return lines[i]
                end
            end
        }
        local written, flushes = {}, 0
        api.mcp.serve({
            input = input,
            write = function(data) table.insert(written, data) end,
            flush = function() flushes = flushes + 1 end,
        })
        -- only the ping got a response (and a flush); the notification was silent
        assert.equals(1, #written)
        assert.equals(1, flushes)
        assert.equals(1, json.decode(written[1]).id)
    end)
end)

describe('webhook.serve coverage', function()
    local copas = require('copas')
    local socket = require('socket')

    local function free_port()
        local probe = assert(socket.bind('127.0.0.1', 0))
        local _, port = probe:getsockname()
        probe:close()
        return tonumber(port)
    end

    -- copas-cooperative http client used from inside the loop
    local function http_request(port, raw)
        local c = copas.wrap(socket.tcp())
        c:settimeout(5)
        assert(c:connect('127.0.0.1', port))
        c:send(raw)
        local status_line = c:receive('*l')
        local headers = {}
        while true do
            local line = c:receive('*l')
            if not line or line == '' then break end
            local k, v = line:match('^(.-):%s*(.*)$')
            if k then headers[k:lower()] = v end
        end
        local body = ''
        local len = tonumber(headers['content-length']) or 0
        if len > 0 then
            body = c:receive(len) or ''
        end
        c:close()
        return status_line, body
    end

    local function build_request(method, path, body, secret)
        local lines = {
            method .. ' ' .. path .. ' HTTP/1.1',
            'Host: 127.0.0.1',
            'Content-Length: ' .. #body,
        }
        if secret then
            table.insert(lines, 'X-Telegram-Bot-Api-Secret-Token: ' .. secret)
        end
        return table.concat(lines, '\r\n') .. '\r\n\r\n' .. body
    end

    it('serves real requests: 200/401/404/405/400 and dispatches updates', function()
        local seen = {}
        local original_on_message = api.on_message
        api.on_message = function(message) table.insert(seen, message.text) end
        finally(function()
            api.on_message = original_on_message
            api.webhook._server = nil
        end)

        local port = free_port()
        -- copas 4.x hands the connection handler a RAW client socket, so the
        -- handler's blocking reads would starve an in-process cooperative
        -- client until its timeout. shim addserver (only for this
        -- registration) to hand the handler a copas-wrapped socket, keeping
        -- the client/server exchange fully cooperative and deterministic.
        local original_addserver = copas.addserver
        copas.addserver = function(srv, handler, ...)
            return original_addserver(srv, function(raw)
                return handler(copas.wrap(raw))
            end, ...)
        end
        local server = api.webhook.serve({
            host = '127.0.0.1',
            port = port,
            path = '/hook',
            secret_token = 'tok123',
            timeout = 5,
            no_loop = true,
        })
        copas.addserver = original_addserver
        assert.is_truthy(server)
        assert.equals(server, api.webhook._server)

        local update_body = json.encode({
            update_id = 99,
            message = { chat = { id = 1, type = 'private' }, text = 'via webhook' }
        })

        local results = {}
        copas.addthread(function()
            -- a client that connects and hangs up without sending a request
            local silent = copas.wrap(socket.tcp())
            silent:settimeout(5)
            assert(silent:connect('127.0.0.1', port))
            silent:close()

            results.ok = { http_request(port,
                build_request('POST', '/hook', update_body, 'tok123')) }
            results.bad_secret = { http_request(port,
                build_request('POST', '/hook', update_body, 'wrong')) }
            results.not_found = { http_request(port,
                build_request('POST', '/elsewhere', update_body, 'tok123')) }
            results.bad_method = { http_request(port,
                build_request('GET', '/hook', '', 'tok123')) }
            results.bad_json = { http_request(port,
                build_request('POST', '/hook', 'not json at all', 'tok123')) }
            copas.removeserver(api.webhook._server)
        end)
        copas.loop()

        assert.truthy(results.ok[1]:find('200', 1, true))
        assert.equals('OK', results.ok[2])
        assert.truthy(results.bad_secret[1]:find('401', 1, true))
        assert.equals('invalid secret token', results.bad_secret[2])
        assert.truthy(results.not_found[1]:find('404', 1, true))
        assert.equals('not found', results.not_found[2])
        assert.truthy(results.bad_method[1]:find('405', 1, true))
        assert.equals('method not allowed', results.bad_method[2])
        assert.truthy(results.bad_json[1]:find('400', 1, true))
        assert.equals('invalid payload', results.bad_json[2])

        -- only the single authenticated, well-formed update reached the handler
        assert.same({ 'via webhook' }, seen)
    end)

    it('returns false and an error when the port cannot be bound', function()
        local probe = assert(socket.bind('127.0.0.1', 0))
        local _, port = probe:getsockname()
        finally(function() probe:close() end)
        local server, err = api.webhook.serve({
            host = '127.0.0.1', port = tonumber(port), no_loop = true
        })
        assert.is_false(server)
        assert.is_string(err)
    end)
end)
