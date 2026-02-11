# Utilities

## Text Formatting (`api.fmt`)

Format text for any parse mode. All methods default to HTML.

```lua
api.fmt.bold('text', 'HTML')           -- <b>text</b>
api.fmt.bold('text', 'MarkdownV2')     -- *text*
api.fmt.italic('text')                 -- <i>text</i>
api.fmt.code('text')                   -- <code>text</code>
api.fmt.pre('code', 'lua')            -- <pre><code class="language-lua">code</code></pre>
api.fmt.link('Click', 'https://...')   -- <a href="https://...">Click</a>
api.fmt.mention(user_id, 'Name')       -- <a href="tg://user?id=...">Name</a>
api.fmt.spoiler('secret')              -- <tg-spoiler>secret</tg-spoiler>
api.fmt.strikethrough('old')           -- <s>old</s>
api.fmt.underline('text')              -- <u>text</u>
api.fmt.blockquote('quote')            -- <blockquote>quote</blockquote>
```

All methods automatically escape special characters for the chosen parse mode.

### Example

```lua
local text = api.fmt.bold('Welcome') .. ', ' .. api.fmt.mention(user.id, user.first_name) .. '!\n'
    .. 'Use ' .. api.fmt.code('/help') .. ' for more info.'
api.send_message(chat_id, text, { parse_mode = 'HTML' })
```

## Command Parsing

### `api.extract_command(message)`

Parse a command from a message object:

```lua
local cmd = api.extract_command(message)
-- cmd.command   = "ban"        (lowercase)
-- cmd.bot       = "mybot"      (or nil)
-- cmd.args      = {"123", "spam"}
-- cmd.args_str  = "123 spam"

if cmd and cmd.command == 'ban' and cmd.args[1] then
    api.ban_chat_member(message.chat.id, cmd.args[1])
end
```

Supports `/`, `!`, and `#` command prefixes.

### `api.is_command(message)`

Quick check if a message starts with a command prefix:

```lua
if api.is_command(message) then
    -- handle command
end
```

## Message Inspection

```lua
api.get_text(message)      -- Returns message.text or message.caption (or nil)
api.get_user_id(obj)       -- Extract sender user ID from any update type
api.get_chat_id(obj)       -- Extract chat ID from any update type
api.get_name(user)         -- Returns "First Last" display name
api.is_reply(message)      -- true if message is a reply
api.is_private(message)    -- true if private chat
api.is_group(message)      -- true if group or supergroup
```

## Deep Links

```lua
-- Generate deep links
api.deep_link('mybot', 'ref123')         -- https://t.me/mybot?start=ref123
api.deep_link_group('mybot', 'setup')    -- https://t.me/mybot?startgroup=setup

-- Parse deep link payload from /start message
local payload = api.parse_deep_link(message)  -- "ref123"
```

## Pagination

Build paginated inline keyboards:

```lua
local items = get_all_items()  -- e.g., 50 items
local result = api.paginate(items, page, 10, 'items')

-- result.items       = items for current page
-- result.page        = current page number
-- result.total_pages = total number of pages
-- result.nav_row     = row with Prev/Next buttons
-- result.has_prev    = boolean
-- result.has_next    = boolean

-- Build keyboard with item buttons + navigation
local kb = api.inline_keyboard()
for _, item in ipairs(result.items) do
    kb:row(api.row():callback_data_button(item.name, 'select:' .. item.id))
end
kb:row(result.nav_row)

api.send_message(chat_id, 'Page ' .. result.page, { reply_markup = kb })

-- Handle page navigation in callback_query handler
local page = api.parse_page_callback(callback_query.data, 'items')
if page then
    -- re-render with new page
end
```

## Callback Data Encoding

Structured callback data for inline buttons (max 64 bytes):

```lua
-- Encode
local data = api.encode_callback('ban', { id = 123, reason = 'spam' })
-- "ban:id=123;reason=spam"

-- Decode
local parsed = api.decode_callback(callback_query.data)
-- parsed.action = "ban"
-- parsed.data.id = 123
-- parsed.data.reason = "spam"
```

## Safe Calls

```lua
local result, extra, err = api.safe_call(api.send_message, chat_id, text)
if not result then
    print('Error: ' .. tostring(err))
end
```

## Typing Indicator

```lua
api.send_typing(chat_id)  -- Shorthand for api.send_chat_action(chat_id, 'typing')
```

## Tools Module

The `tools` module provides low-level utility functions:

```lua
local tools = require('telegram-bot-lua.tools')
```

### Text Processing

```lua
tools.escape_html(str)          -- Escape &, <, > for HTML parse mode
tools.escape_markdown(str)      -- Escape for Markdown parse mode
tools.escape_markdown_v2(str)   -- Escape for MarkdownV2 parse mode
tools.escape_bash(str)          -- Shell-safe quoting
tools.utf8_len(str)             -- UTF-8 aware string length
tools.trim(str)                 -- Trim whitespace
tools.get_word(str, n)          -- Get nth word (1-indexed)
tools.input(str)                -- Get text after first space (command args)
tools.split_string(str, reverse)           -- Split by whitespace
tools.string_array_to_table(str)           -- Split comma-separated string
tools.create_link(text, url, parse_mode)   -- Create formatted link
tools.get_formatted_user(id, name, mode)   -- Create user mention link
```

### Number Formatting

```lua
tools.comma_value(1000000)      -- "1,000,000"
tools.format_ms(3661000)        -- "01:01:01"
tools.format_time(3600)         -- "1 hour"
tools.round(3.14159, 2)         -- 3.14
```

### Table Utilities

```lua
tools.table_size(t)                   -- Count all key-value pairs
tools.table_contains(t, value)        -- Check if value exists
tools.is_duplicate(t, value)          -- Check for duplicates
tools.pretty_print(t)                 -- JSON-formatted string
```

### Message Analysis

```lua
tools.service_message(message)   -- Returns is_service, type
tools.is_media(message)          -- true if message contains media
tools.media_type(message)        -- "photo", "video", "text", etc.
tools.file_id(message, unique)   -- Extract file_id from any media type
```

### File Operations

```lua
tools.file_exists(path)                    -- Check if file exists
tools.read_file(path)                      -- Read file contents
tools.file_size(path)                      -- Get file size in bytes
tools.get_file_as_table(path)              -- Read lines into table
tools.json_to_table(path)                  -- Parse JSON file to table
tools.save_to_file(data, filename, append) -- Save to /tmp/
tools.download_file(url, name, path)       -- Download URL to disk
```

### Command Matching

```lua
local cmds = tools.commands('mybot_username')
cmds:command('start')
cmds:command('help')

-- cmds.table contains patterns for matching:
-- /start, /start@mybot, /start args, /start@mybot args
for _, pattern in pairs(cmds.table) do
    if message.text:match(pattern) then
        -- matched
    end
end
```

### Crypto/Encoding

```lua
tools.random_string(length, amount)              -- Generate random alphanumeric string(s)
tools.string_hexdump(data, length, size, space)   -- Hex dump of binary data
tools.rle_encode(str) / tools.rle_decode(str)     -- Run-length encoding
tools.unpack_file_id(file_id, media_type)          -- Decode Telegram file ID
tools.unpack_inline_message_id(inline_message_id)  -- Decode inline message ID
tools.unpack_telegram_invite_link(link)             -- Decode invite link
```

### URL Validation

```lua
tools.is_valid_url('https://example.com')          -- true
tools.is_valid_url('example.com')                   -- true (auto-prepends http://)
tools.is_valid_url('https://example.com/path', true) -- Returns parts table
```

### Symbols

```lua
tools.symbols.back      -- ← (U+2190)
tools.symbols.forward   -- → (U+2192)
tools.symbols.bullet    -- • (U+2022)
```
