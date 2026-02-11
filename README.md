# telegram-bot-lua

A feature-filled Telegram bot API library written in Lua, created by [Matt](https://t.me/wrxck). Supports Bot API 9.4 with full coverage of all available methods.

## Installation

Requires Lua 5.1+ and LuaRocks:

```
luarocks install telegram-bot-lua
```

## Quick Start

```lua
local api = require('telegram-bot-lua').configure('YOUR_BOT_TOKEN')

function api.on_message(message)
    if message.text then
        api.send_message(message.chat.id, 'You said: ' .. message.text)
    end
end

function api.on_callback_query(callback_query)
    api.answer_callback_query(callback_query.id, { text = 'Received!' })
end

api.run({ timeout = 60 })
```

## Key Features

- Full Bot API 9.4 coverage (messages, media, payments, stickers, forums, games, gifts, stories, and more)
- **Lua 5.1 - 5.5 support** with automatic polyfills for bitwise operations and string.pack
- **Async concurrency** via copas: concurrent update processing, parallel API calls, background tasks
- Clean opts-table pattern for all API methods
- Chainable keyboard and inline result builders
- Text formatting helpers for HTML, Markdown, and MarkdownV2
- Command parsing, pagination, deep links, and callback data encoding
- Member status helpers and chat permission checks
- Legacy v2 compatibility layer with deprecation warnings

## Documentation

| Document | Description |
|---|---|
| [Getting Started](docs/getting-started.md) | Installation, configuration, and first bot |
| [Update Handlers](docs/handlers.md) | All available update handler functions |
| [API Methods](docs/methods.md) | Complete method reference |
| [Builders](docs/builders.md) | Keyboards, inline results, and type constructors |
| [Utilities](docs/utilities.md) | Formatting, command parsing, pagination, and tools |
| [Async / Concurrency](docs/async.md) | Concurrent updates, parallel calls, background tasks |
| [Migration from v2](docs/migration.md) | Breaking changes and upgrade guide |

## Example

```lua
local api = require('telegram-bot-lua').configure('YOUR_TOKEN')
local tools = require('telegram-bot-lua.tools')

function api.on_message(message)
    local cmd = api.extract_command(message)
    if not cmd then return end

    if cmd.command == 'start' then
        local payload = api.parse_deep_link(message)
        local name = api.fmt.bold(api.get_name(message.from))
        api.send_message(message.chat.id, 'Welcome, ' .. name .. '!', {
            parse_mode = 'HTML',
            reply_markup = api.inline_keyboard()
                :row(api.row()
                    :callback_data_button('Help', 'help')
                    :url_button('Website', 'https://example.com'))
        })
    elseif cmd.command == 'info' then
        api.send_typing(message.chat.id)
        local text = api.fmt.code(tools.pretty_print(message.from))
        api.send_message(message.chat.id, text, { parse_mode = 'HTML' })
    end
end

function api.on_callback_query(callback_query)
    local parsed = api.decode_callback(callback_query.data)
    if parsed and parsed.action == 'help' then
        api.answer_callback_query(callback_query.id, { text = 'Use /start to begin!' })
    end
end

api.run({ timeout = 60 })
```

## Module Structure

```
src/
  init.lua              -- Entry point, core HTTP, module loader
  config.lua            -- API endpoint configuration
  polyfill.lua          -- Lua 5.1+ compatibility (bit ops, string.pack)
  async.lua             -- Copas-based concurrency module
  b64url.lua            -- Base64 URL encoding/decoding
  tools.lua             -- Utility functions (formatting, file ops, etc.)
  handlers.lua          -- Update routing and on_* handler stubs
  builders.lua          -- Keyboard, inline result, and type constructors
  helpers.lua           -- Member status check helpers
  utils.lua             -- Bot development utilities (fmt, commands, pagination)
  compat.lua            -- v2 backward compatibility layer
  methods/
    messages.lua        -- send_*, forward_*, copy_*, edit_*, delete_*
    updates.lua         -- get_updates, webhooks
    chat.lua            -- Chat management
    members.lua         -- Member management (ban, restrict, promote)
    forum.lua           -- Forum topic management
    stickers.lua        -- Sticker operations
    inline.lua          -- Inline queries and callback queries
    payments.lua        -- Invoices, payments, stars
    games.lua           -- Game methods
    passport.lua        -- Passport data errors
    bot.lua             -- Bot profile and settings
    gifts.lua           -- Gift methods
    checklists.lua      -- Checklist methods
    stories.lua         -- Story methods
    suggested_posts.lua -- Suggested post methods
```

## Testing

```
luarocks install busted
busted
```

## License

This project is licensed under the GPL-3.0 License - see the LICENSE file for details.

Copyright (c) 2017-2026 Matthew Hesketh
