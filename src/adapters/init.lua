--- adapter registry for database, Redis, LLM, and email adapters.
-- @module telegram-bot-lua.adapters
--[[
    Adapter registry for telegram-bot-lua.
    Provides a unified interface for database, Redis, LLM, and email adapters.
    All adapters are async-first: they use non-blocking I/O when running
    inside a copas context and fall back to synchronous I/O otherwise.
]]

return function(api)
    api.adapters = {}

    --- check if we're inside a copas async context.
    -- @return boolean true if running inside copas
    function api.adapters.is_async()
        local ok, copas = pcall(require, 'copas')
        if not ok then return false end
        if type(copas.running) == 'function' then
            return copas.running()
        end
        return copas.running == true
    end

    --- perform an HTTP request that auto-selects sync or async transport.
    -- @param url string the request URL
    -- @param opts table optional request options (method, headers, body)
    -- @return string response body, or nil on error
    -- @return number HTTP status code or error message
    function api.adapters.http_request(url, opts)
        opts = opts or {}
        local method = opts.method or 'GET'
        local headers = opts.headers or {}
        local body = opts.body

        -- the two transports share everything but the request function:
        -- copas.http when async, and scheme-appropriate luasocket otherwise
        -- (ssl.https cannot speak plain http, so http:// urls must go
        -- through socket.http).
        local request_fn
        if api.adapters.is_async() then
            request_fn = require('copas.http').request
        elseif url:lower():match('^http://') then
            request_fn = require('socket.http').request
        else
            request_fn = require('ssl.https').request
        end

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
        local ok, status_code, resp_headers = request_fn(req)
        if not ok then
            return nil, status_code
        end
        return table.concat(response_body), status_code, resp_headers
    end

    --- create a TCP socket that auto-selects sync or async mode.
    -- @return userdata a TCP socket, wrapped with copas if in async context
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
