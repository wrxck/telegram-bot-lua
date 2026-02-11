# Migration from v2 to v3

## Compatibility Layer

v3 includes a compatibility layer that handles the most common v2 patterns automatically. You'll see deprecation warnings in the console when v2 patterns are used.

## Required Changes

### 1. Module entry point

```lua
-- v2
local api = require('telegram-bot-lua.core').configure('TOKEN')

-- v3
local api = require('telegram-bot-lua').configure('TOKEN')
```

`require('telegram-bot-lua.core')` still works but prints a deprecation warning.

### 2. Options table pattern

All API methods with optional parameters now use an opts table instead of positional arguments.

```lua
-- v2
api.send_message(chat_id, text, nil, 'HTML', nil, nil, nil, nil, nil, reply_markup)

-- v3
api.send_message(chat_id, text, { parse_mode = 'HTML', reply_markup = markup })
```

The compatibility layer auto-detects some v2 positional patterns:

```lua
-- These still work (with deprecation warning):
api.send_message(chat_id, text, 'HTML')            -- parse_mode as 3rd arg
api.answer_callback_query(id, 'text', true)         -- text + show_alert
api.edit_message_text(chat_id, msg_id, text, 'HTML') -- parse_mode as 4th arg
```

### 3. Renamed methods

| v2 | v3 |
|---|---|
| `api.get_chat_members_count(id)` | `api.get_chat_member_count(id)` |
| `api.kick_chat_member(chat_id, user_id, until)` | `api.ban_chat_member(chat_id, user_id, opts)` |

The v2 names still work via the compatibility layer.

### 4. `api.run()` opts table

```lua
-- v2
api.run(limit, timeout, offset, allowed_updates, use_beta_endpoint)

-- v3
api.run({ limit = 100, timeout = 60 })
```

### 5. Constructor opts tables

```lua
-- v2
api.chat_permissions(true, true, true, true, true, true, true, true)

-- v3
api.chat_permissions({ can_send_messages = true, can_send_photos = true })
```

## Bug Fixes in v3

These bugs from v2 are fixed in v3:

1. **`is_user_group_admin`**: Now correctly checks both `'administrator'` and `'creator'` status. v2 had `('administrator' or 'creator')` which in Lua always evaluates to `'administrator'`.

2. **`is_user_restricted`**: Now correctly checks `'restricted'` status. v2 was checking `'kicked'` instead.

3. **`ban_chat_member`**: Now uses the correct `/banChatMember` endpoint. v2 was still using the deprecated `/kickChatMember`.

4. **`get_chat_member_count`**: Uses `/getChatMemberCount` endpoint. v2 used the deprecated `/getChatMembersCount`.

5. **`process_update`**: Fixed missing parentheses on several handler calls (`on_poll_answer`, `on_message_reaction`, etc.) and fixed nil update crash.

6. **`format_ms`**: Hours are now correctly calculated from total seconds. v2 calculated hours from floored minutes, giving wrong results for large values.

7. **`get_formatted_user`**: Fixed `type(parse_mode) == ('nil' or 'boolean')` which always evaluated to `type(parse_mode) == 'nil'` in Lua.

8. **`random_string`**: No longer shells out to `shuf` (security fix). Uses `math.random` with proper seeding.

9. **`tools.trim`**: No longer leaks gsub count as second return value.

## Removed Features

- `get_chat` no longer scrapes t.me for bio information (was fragile HTML scraping)
- `unban_chat_member` no longer has an internal retry loop

## New Features

See [Utilities](utilities.md) for new helper functions including text formatting, command parsing, pagination, deep links, and callback data encoding.
