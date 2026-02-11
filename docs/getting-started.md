# Getting Started

## Installation

Requires Lua 5.1+ and LuaRocks:

```
luarocks install telegram-bot-lua
```

Optional adapter dependencies:

```
luarocks install lsqlite3   # SQLite database adapter
luarocks install pgmoon      # PostgreSQL database adapter
```

## Quick Start

```lua
local api = require('telegram-bot-lua').configure('YOUR_BOT_TOKEN')

function api.on_message(message)
    if message.text then
        api.send_message(message.chat.id, 'You said: ' .. message.text)
    end
end

api.run({ timeout = 60 })
```

`api.run()` is async by default: each update is processed in its own coroutine, so a slow handler won't block other updates. All API calls are non-blocking within `api.run()`.

## Configuration

```lua
-- Basic configuration
local api = require('telegram-bot-lua').configure('YOUR_BOT_TOKEN')

-- With debug logging
local api = require('telegram-bot-lua').configure('YOUR_BOT_TOKEN', true)

-- Run with options (async by default)
api.run({
    limit = 100,       -- Max updates per poll (1-100)
    timeout = 60,       -- Long polling timeout in seconds
    allowed_updates = { 'message', 'callback_query' }  -- Filter update types
})

-- Single-threaded mode (opt-in)
api.run({ sync = true, timeout = 60 })
```

## Bot Information

After calling `configure()`, bot information is available at `api.info`:

```lua
api.info.id           -- Bot's user ID
api.info.first_name   -- Bot's first name
api.info.username     -- Bot's username
api.info.name         -- Alias for first_name
```

## Sending Messages

All methods follow the pattern: required args positional, optional args in an `opts` table.

```lua
-- Simple text message
api.send_message(chat_id, 'Hello!')

-- With formatting
api.send_message(chat_id, '<b>Bold</b> text', { parse_mode = 'HTML' })

-- With inline keyboard
api.send_message(chat_id, 'Choose:', {
    reply_markup = api.inline_keyboard()
        :row(api.row():callback_data_button('Yes', 'yes'):callback_data_button('No', 'no'))
})

-- Reply to a message
api.send_reply(message, 'Got it!', { parse_mode = 'HTML' })
```

## Handling Updates

Override handler functions on the `api` table:

```lua
function api.on_message(message)
    -- Handle all new messages
end

function api.on_callback_query(callback_query)
    -- Handle button clicks
    api.answer_callback_query(callback_query.id, { text = 'Clicked!' })
end

function api.on_inline_query(inline_query)
    -- Handle inline queries
end
```

See [Update Handlers](handlers.md) for the complete list.

## Error Handling

API methods return two values: `result, error_info`.

```lua
local result, err = api.send_message(chat_id, text)
if not result then
    print('Failed:', err)
end
```

Use `api.safe_call` to wrap calls with pcall:

```lua
local result, extra, err = api.safe_call(api.send_message, chat_id, text)
```

## Next Steps

- [API Methods Reference](methods.md) - All available API methods
- [Builders](builders.md) - Keyboards, inline results, and constructors
- [Utilities](utilities.md) - Helper functions and formatting
- [Async / Concurrency](async.md) - Concurrent update processing and parallel operations
- [Adapters](adapters.md) - Database, Redis, LLM, and email integrations
- [Migration from v2](migration.md) - Upgrading from v2
