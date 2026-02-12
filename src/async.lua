--[[
    Async module for telegram-bot-lua.
    Provides coroutine-based concurrency via copas for non-blocking
    API requests, concurrent update processing, and parallel operations.

    Usage:
        -- Process updates concurrently (each handler in its own coroutine)
        api.async.run({ timeout = 60 })

        -- Inside a handler, run multiple API calls in parallel
        local results = api.async.all({
            function() return api.send_message(chat1, 'msg1') end,
            function() return api.send_message(chat2, 'msg2') end,
        })

        -- Spawn a background task
        api.async.spawn(function()
            api.send_typing(chat_id)
            copas.sleep(2)
            api.send_message(chat_id, 'Done thinking!')
        end)

        -- Sleep without blocking other coroutines
        api.async.sleep(1.5)
]]

return function(api)
    local copas = require('copas')
    local copas_http = require('copas.http')
    local ltn12 = require('ltn12')
    local multipart = require('multipart-post')
    local json = require('dkjson')

    api.async = {}
    api.async._running = false

    -- Non-blocking HTTP request using copas.
    -- Has the same signature as api.request but uses copas.http.
    function api.async.request(endpoint, parameters, file)
        assert(endpoint, 'You must specify an endpoint to make this request to!')
        parameters = parameters or {}
        for k, v in pairs(parameters) do
            parameters[k] = tostring(v)
        end
        if api.debug then
            local safe = {}
            for k, v in pairs(parameters) do safe[k] = v end
            local output = json.encode(safe, { ['indent'] = true })
            print(output)
        end
        if file and next(file) ~= nil then
            local file_type, file_name = next(file)
            if type(file_name) == 'string' then
                local file_res = io.open(file_name, 'rb')
                if file_res then
                    parameters[file_type] = {
                        filename = file_name,
                        data = file_res:read('*a')
                    }
                    file_res:close()
                else
                    parameters[file_type] = file_name
                end
            else
                parameters[file_type] = file_name
            end
        end
        parameters = next(parameters) == nil and {''} or parameters
        local response = {}
        local body, boundary = multipart.encode(parameters)
        local success, res = copas_http.request({
            ['url'] = endpoint,
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
                ['Content-Length'] = #body
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        })
        if not success then
            print('Connection error [' .. tostring(res) .. ']')
            return false, res
        end
        local jstr = table.concat(response)
        local jdat = json.decode(jstr)
        if not jdat then
            return false, res
        elseif not jdat.ok then
            if api.debug then
                local output = '\n' .. tostring(jdat.description) .. ' [' .. tostring(jdat.error_code) .. ']\n'
                print(output)
            end
            return false, jdat
        end
        return jdat, res
    end

    -- Run the bot with concurrent update processing.
    -- Each update is dispatched to its own coroutine so a slow handler
    -- won't block processing of other updates.
    function api.async.run(opts)
        opts = opts or {}
        local limit = tonumber(opts.limit) or 1
        local timeout = tonumber(opts.timeout) or 0
        local offset = tonumber(opts.offset) or 0
        local allowed_updates = opts.allowed_updates

        -- Swap request function to use async version within copas context
        local sync_request = api.request
        api.request = api.async.request
        api.async._running = true

        copas.addthread(function()
            while api.async._running do
                local updates = api.get_updates({
                    timeout = timeout,
                    offset = offset,
                    limit = limit,
                    allowed_updates = allowed_updates
                })
                if updates and type(updates) == 'table' and updates.result then
                    for _, v in pairs(updates.result) do
                        -- Each update gets its own coroutine
                        copas.addthread(function()
                            local ok, err = pcall(api.process_update, v)
                            if not ok and api.debug then
                                print('Update handler error: ' .. tostring(err))
                            end
                        end)
                        offset = v.update_id + 1
                    end
                end
            end
        end)

        copas.loop()

        -- Restore sync request when loop exits
        api.request = sync_request
        api.async._running = false
    end

    -- Stop the async run loop.
    function api.async.stop()
        api.async._running = false
    end

    -- Run multiple functions concurrently and collect results.
    -- Each function runs in its own coroutine. Returns when all complete.
    -- Results are returned in order: { {ok, result, ...}, {ok, result, ...} }
    function api.async.all(fns)
        if not fns or #fns == 0 then
            return {}
        end

        local results = {}
        local remaining = #fns

        -- If already inside copas, use semaphore for synchronization
        local in_copas = type(copas.running) == 'function' and copas.running() or copas.running
        if in_copas then
            for i, fn in ipairs(fns) do
                copas.addthread(function()
                    results[i] = {pcall(fn)}
                    remaining = remaining - 1
                end)
            end
            -- Yield until all tasks complete
            while remaining > 0 do
                copas.pause()
            end
        else
            -- Not in copas context: start a mini loop
            for i, fn in ipairs(fns) do
                copas.addthread(function()
                    results[i] = {pcall(fn)}
                end)
            end
            copas.loop()
        end

        -- Unwrap results: if pcall succeeded, return the values directly
        local unwrapped = {}
        for i, r in ipairs(results) do
            if r[1] then
                -- pcall success: remove the true and return values
                unwrapped[i] = { select(2, (table.unpack or unpack)(r)) }
            else
                -- pcall failure: return false and the error
                unwrapped[i] = { false, r[2] }
            end
        end
        return unwrapped
    end

    -- Spawn a background coroutine within the copas event loop.
    -- Returns the copas thread.
    function api.async.spawn(fn)
        return copas.addthread(fn)
    end

    -- Non-blocking sleep. Only works within a copas coroutine context.
    function api.async.sleep(seconds)
        copas.sleep(seconds)
    end

    -- Check if we're currently inside the async event loop.
    function api.async.is_running()
        return api.async._running
    end
end
