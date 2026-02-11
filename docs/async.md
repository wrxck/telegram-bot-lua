# Async / Concurrency

telegram-bot-lua v3.0 is async-first. The framework uses coroutine-based concurrency powered by [copas](https://github.com/lunarmodules/copas), enabling non-blocking update processing, parallel API calls, and background tasks out of the box.

## Async by Default

`api.run()` uses async concurrency by default. Each update is dispatched in its own coroutine, so a slow handler won't block others. All API calls automatically use non-blocking HTTP.

```lua
local api = require('telegram-bot-lua').configure('YOUR_BOT_TOKEN')

function api.on_message(message)
    -- This runs in its own coroutine per update.
    -- A slow operation here won't block other updates.
    api.send_message(message.chat.id, 'Processing...')
    api.async.sleep(2)
    api.send_message(message.chat.id, 'Done!')
end

api.run({ timeout = 60 })
```

For single-threaded sequential processing, opt in with `sync = true`:

```lua
api.run({ sync = true, timeout = 60 })
```

`api.async.run()` is still available as an explicit alias for async mode.

## Parallel Operations

Use `api.async.all()` to run multiple functions concurrently and collect results:

```lua
function api.on_message(message)
    local results = api.async.all({
        function() return api.send_message(chat1, 'Hello') end,
        function() return api.send_message(chat2, 'Hello') end,
        function() return api.send_message(chat3, 'Hello') end,
    })
    -- results[1][1] = result of first call
    -- results[2][1] = result of second call
    -- results[3][1] = result of third call
end
```

Results are returned in order, matching the input function order. Each result is a table of return values. If a function errors, its result is `{ false, error_message }`.

`api.async.all()` works both inside and outside the copas event loop. Outside copas, it starts a temporary loop to execute the functions.

## Background Tasks

Use `api.async.spawn()` to launch a fire-and-forget coroutine:

```lua
function api.on_message(message)
    -- Reply immediately
    api.send_message(message.chat.id, 'Working on it...')

    -- Do heavy work in background
    api.async.spawn(function()
        api.async.sleep(5)
        api.send_message(message.chat.id, 'Finished!')
    end)
end
```

## Non-blocking Sleep

`api.async.sleep(seconds)` yields the current coroutine for the given duration without blocking other coroutines:

```lua
api.async.sleep(1.5)  -- sleep 1.5 seconds, other coroutines continue
```

## Control Functions

```lua
api.async.stop()         -- Stop the run loop
api.async.is_running()   -- Returns true if inside the async event loop
```

## Non-blocking HTTP Requests

`api.async.request()` has the same signature as `api.request()` but uses copas HTTP for non-blocking I/O. During `api.run()`, this is used automatically for all API calls.

```lua
-- Manual usage (inside a copas context)
local result, status = api.async.request(endpoint, parameters, file)
```

## Adapter Integration

All built-in adapters (database, Redis, LLM, email) are async-aware. They automatically use non-blocking I/O when running inside `api.run()`:

```lua
function api.on_message(message)
    -- These are all non-blocking inside api.run()
    local rows = db:query('SELECT * FROM users WHERE id = ?', {message.from.id})
    local cached = redis:get('user:' .. message.from.id)
    local result = llm:chat({{ role = 'user', content = message.text }})
end
```

## Lua Version Compatibility

The async module uses copas, which works on Lua 5.1 through 5.4 and LuaJIT. No special compatibility handling is needed.
