--[[
    Adapter registry for telegram-bot-lua.
    Provides a unified interface for database, Redis, LLM, and email adapters.
    All adapters are async-first: they use non-blocking I/O when running
    inside a copas context and fall back to synchronous I/O otherwise.
]]

return function(api)
    api.adapters = {}

    -- Utility: check if we're inside a copas async context
    function api.adapters.is_async()
        local ok, copas = pcall(require, 'copas')
        if not ok then return false end
        if type(copas.running) == 'function' then
            return copas.running()
        end
        return copas.running == true
    end

    -- Utility: perform an HTTP request that auto-selects sync/async
    function api.adapters.http_request(url, opts)
        opts = opts or {}
        local method = opts.method or 'GET'
        local headers = opts.headers or {}
        local body = opts.body

        if api.adapters.is_async() then
            local copas_http = require('copas.http')
            local ltn12 = require('ltn12')
            local response_body = {}
            local req = {
                url = url,
                method = method,
                headers = headers,
                sink = ltn12.sink.table(response_body),
            }
            if body then
                req.source = ltn12.source.string(body)
                headers['Content-Length'] = tostring(#body)
            end
            local ok, status_code, resp_headers = copas_http.request(req)
            if not ok then
                return nil, status_code
            end
            return table.concat(response_body), status_code, resp_headers
        else
            local https = require('ssl.https')
            local ltn12 = require('ltn12')
            local response_body = {}
            local req = {
                url = url,
                method = method,
                headers = headers,
                sink = ltn12.sink.table(response_body),
            }
            if body then
                req.source = ltn12.source.string(body)
                headers['Content-Length'] = tostring(#body)
            end
            local ok, status_code, resp_headers = https.request(req)
            if not ok then
                return nil, status_code
            end
            return table.concat(response_body), status_code, resp_headers
        end
    end

    -- Utility: create a TCP socket that auto-selects sync/async
    function api.adapters.create_socket()
        local socket = require('socket')
        local sock = socket.tcp()
        if api.adapters.is_async() then
            local copas = require('copas')
            return copas.wrap(sock)
        end
        return sock
    end

    -- Load adapter modules
    require('telegram-bot-lua.adapters.db')(api)
    require('telegram-bot-lua.adapters.redis')(api)
    require('telegram-bot-lua.adapters.llm')(api)
    require('telegram-bot-lua.adapters.email')(api)
end
