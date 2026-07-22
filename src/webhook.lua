--- webhook receiver for incoming updates.
-- two entry points: api.webhook.process (verify + dispatch a body you already
-- received via your own http server) and api.webhook.serve (a turnkey copas
-- http server). both verify the x-telegram-bot-api-secret-token when a secret
-- is configured.
-- @module telegram-bot-lua.webhook
return function(api)
    api.webhook = {}

    -- all-bytes comparison (no early exit) to avoid leaking the secret via timing.
    local function constant_eq(a, b)
        if type(a) ~= 'string' or type(b) ~= 'string' or #a ~= #b then
            return false
        end
        local diff = 0
        for i = 1, #a do
            if a:byte(i) ~= b:byte(i) then diff = 1 end
        end
        return diff == 0
    end

    --- check a received secret token against the expected one.
    -- when no secret is configured (expected nil or empty) verification passes.
    -- @param received string|nil the x-telegram-bot-api-secret-token header value
    -- @param expected string|nil the secret configured with setWebhook
    -- @return boolean true if acceptable
    function api.webhook.verify_secret(received, expected)
        if expected == nil or expected == '' then
            return true
        end
        return constant_eq(received, expected)
    end

    --- verify a secret then dispatch an update body received from telegram.
    -- @param body string|table raw JSON body, or an already-decoded update table
    -- @param opts table optional { secret_token, received_secret }
    -- @return any|false the dispatch result, or false + reason on failure
    function api.webhook.process(body, opts)
        opts = opts or {}
        if not api.webhook.verify_secret(opts.received_secret, opts.secret_token) then
            return false, 'invalid secret token'
        end
        local update = type(body) == 'table' and body or api._json_decode(body or '')
        if type(update) ~= 'table' then
            return false, 'invalid update payload'
        end
        return api.process_update(update)
    end

    -- pure request handler: decides the http status + body for a parsed request.
    -- @return number status, string response_body
    function api.webhook._dispatch(method, target, headers, body, opts)
        opts = opts or {}
        headers = headers or {}
        if method ~= 'POST' then
            return 405, 'method not allowed'
        end
        if opts.path and opts.path ~= '' and target:sub(1, #opts.path) ~= opts.path then
            return 404, 'not found'
        end
        if not api.webhook.verify_secret(headers['x-telegram-bot-api-secret-token'], opts.secret_token) then
            return 401, 'invalid secret token'
        end
        local update = api._json_decode(body or '')
        if type(update) ~= 'table' then
            return 400, 'invalid payload'
        end
        -- never let a handler error take down the server.
        pcall(api.process_update, update)
        return 200, 'OK'
    end

    --- run a minimal copas http server that receives telegram webhooks.
    -- pass { no_loop = true } to register the server without entering copas.loop()
    -- (useful when you already run your own loop).
    -- @param opts table { host, port, path, secret_token, timeout, no_loop }
    -- @return table|false the bound server socket, or false + error
    function api.webhook.serve(opts)
        opts = opts or {}
        local copas = require('copas')
        local socket = require('socket')
        local host = opts.host or '0.0.0.0'
        local port = tonumber(opts.port) or 8443
        local server, err = socket.bind(host, port)
        if not server then
            return false, err
        end
        api.webhook._server = server
        copas.addserver(server, function(skt)
            skt:settimeout(tonumber(opts.timeout) or 10)
            local request_line = skt:receive('*l')
            if not request_line then
                skt:close()
                return
            end
            local method, target = request_line:match('^(%S+)%s+(%S+)')
            local headers = {}
            while true do
                local line = skt:receive('*l')
                if not line or line == '' then
                    break
                end
                local k, v = line:match('^(.-):%s*(.*)$')
                if k then
                    headers[k:lower()] = v
                end
            end
            local body = ''
            local len = tonumber(headers['content-length']) or 0
            if len > 0 then
                body = skt:receive(len) or ''
            end
            local status, payload = api.webhook._dispatch(method or '', target or '/', headers, body, opts)
            local response = string.format(
                'HTTP/1.1 %d %s\r\nContent-Type: text/plain\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s',
                status, status == 200 and 'OK' or 'Error', #payload, payload)
            skt:send(response)
            skt:close()
        end)
        if not opts.no_loop then
            copas.loop()
        end
        return server
    end
end
