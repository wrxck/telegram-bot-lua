--- utility functions for formatting, command parsing, and convenience helpers.
-- @module telegram-bot-lua.utils
return function(api)
    local tools = require('telegram-bot-lua.tools')

    -- text formatting helpers for different parse modes

    api.fmt = {}

    --- format text as bold.
    -- @param text string the text to format
    -- @param parse_mode string 'HTML', 'MarkdownV2', or 'Markdown' (default 'HTML')
    -- @return string formatted text
    function api.fmt.bold(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<b>' .. tools.escape_html(text) .. '</b>'
        elseif parse_mode:lower() == 'markdownv2' then
            return '*' .. tools.escape_markdown_v2(text) .. '*'
        end
        return '*' .. tools.escape_markdown(text) .. '*'
    end

    --- format text as italic.
    -- @param text string the text to format
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted text
    function api.fmt.italic(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<i>' .. tools.escape_html(text) .. '</i>'
        elseif parse_mode:lower() == 'markdownv2' then
            return '_' .. tools.escape_markdown_v2(text) .. '_'
        end
        return '_' .. tools.escape_markdown(text) .. '_'
    end

    --- format text as inline code.
    -- @param text string the text to format
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted text
    function api.fmt.code(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<code>' .. tools.escape_html(text) .. '</code>'
        end
        -- inside markdown code entities, backticks and backslashes must be
        -- escaped or they break out of / corrupt the entity.
        local escaped = tostring(text):gsub('([`\\])', '\\%1')
        return '`' .. escaped .. '`'
    end

    --- format text as a pre-formatted code block.
    -- @param text string the text to format
    -- @param language string optional programming language for syntax highlighting
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted text
    function api.fmt.pre(text, language, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            if language then
                return '<pre><code class="language-' .. tools.escape_html(language) .. '">' .. tools.escape_html(text) .. '</code></pre>'
            end
            return '<pre>' .. tools.escape_html(text) .. '</pre>'
        end
        -- inside markdown code entities, backticks and backslashes must be
        -- escaped or they break out of / corrupt the entity (same hazard as
        -- fmt.code); the language tag additionally must not contain newlines.
        local fence = '```'
        local escaped = tostring(text):gsub('([`\\])', '\\%1')
        local lang = language and tostring(language):gsub('[`\\\n]', '') or ''
        return fence .. lang .. '\n' .. escaped .. '\n' .. fence
    end

    --- format text as a hyperlink.
    -- @param text string the link text
    -- @param url string the URL
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted link
    function api.fmt.link(text, url, parse_mode)
        return tools.create_link(text, url, parse_mode or 'HTML')
    end

    --- format a user mention link.
    -- @param user_id number the user ID
    -- @param name string the display name
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted mention
    function api.fmt.mention(user_id, name, parse_mode)
        return tools.get_formatted_user(user_id, name, parse_mode or 'HTML')
    end

    --- format text as a spoiler.
    -- @param text string the text to hide
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted spoiler
    function api.fmt.spoiler(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<tg-spoiler>' .. tools.escape_html(text) .. '</tg-spoiler>'
        end
        return '||' .. tools.escape_markdown_v2(text) .. '||'
    end

    --- format text with strikethrough.
    -- @param text string the text to strike through
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted text
    function api.fmt.strikethrough(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<s>' .. tools.escape_html(text) .. '</s>'
        end
        return '~' .. tools.escape_markdown_v2(text) .. '~'
    end

    --- format text with underline.
    -- @param text string the text to underline
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted text
    function api.fmt.underline(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<u>' .. tools.escape_html(text) .. '</u>'
        end
        return '__' .. tools.escape_markdown_v2(text) .. '__'
    end

    --- format text as a block quote.
    -- @param text string the text to quote
    -- @param parse_mode string parse mode (default 'HTML')
    -- @return string formatted block quote
    function api.fmt.blockquote(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<blockquote>' .. tools.escape_html(text) .. '</blockquote>'
        end
        -- escape each quoted line like the other markdown fmt helpers do;
        -- unescaped special characters are invalid MarkdownV2.
        local lines = {}
        for line in (text .. '\n'):gmatch('(.-)\n') do
            lines[#lines + 1] = '>' .. tools.escape_markdown_v2(line)
        end
        return table.concat(lines, '\n')
    end

    --- extract command, arguments, and bot username from a message.
    -- @param message table the message object
    -- @return table|false parsed command table with command, bot, args, args_str fields, or false
    function api.extract_command(message)
        if type(message) ~= 'table' then
            return false
        end
        local text = message.text or message.caption
        if not text then
            return false
        end
        -- commands and bot usernames may legally contain underscores, which
        -- %w does not match.
        local cmd, bot_username = text:match('^[/!#]([%w_]+)@([%w_]+)')
        if not cmd then
            cmd = text:match('^[/!#]([%w_]+)')
        end
        if not cmd then
            return false
        end
        local args_str = text:match('^[/!#][%w_]+@?[%w_]*%s+(.+)$')
        local args = {}
        if args_str then
            for word in args_str:gmatch('%S+') do
                args[#args + 1] = word
            end
        end
        return {
            command = cmd:lower(),
            bot = bot_username,
            args = args,
            args_str = args_str or ''
        }
    end

    --- get the text content of a message (text or caption).
    -- @param message table the message object
    -- @return string|nil the message text or caption
    function api.get_text(message)
        if type(message) ~= 'table' then
            return nil
        end
        return message.text or message.caption
    end

    --- get the sender's user ID from any update type.
    -- @param obj table the update or message object
    -- @return number|nil the user ID
    function api.get_user_id(obj)
        if type(obj) ~= 'table' then
            return nil
        end
        if obj.from and obj.from.id then
            return obj.from.id
        end
        if obj.message and obj.message.from then
            return obj.message.from.id
        end
        return nil
    end

    --- get the chat ID from any update type.
    -- @param obj table the update or message object
    -- @return number|nil the chat ID
    function api.get_chat_id(obj)
        if type(obj) ~= 'table' then
            return nil
        end
        if obj.chat and obj.chat.id then
            return obj.chat.id
        end
        if obj.message and obj.message.chat then
            return obj.message.chat.id
        end
        return nil
    end

    --- generate a deep link URL for the bot.
    -- @param bot_username string the bot's username
    -- @param payload string the start parameter value
    -- @return string the deep link URL
    function api.deep_link(bot_username, payload)
        return 'https://t.me/' .. bot_username .. '?start=' .. tostring(payload)
    end

    --- generate a deep link URL for adding the bot to a group.
    -- @param bot_username string the bot's username
    -- @param payload string the startgroup parameter value
    -- @return string the deep link URL
    function api.deep_link_group(bot_username, payload)
        return 'https://t.me/' .. bot_username .. '?startgroup=' .. tostring(payload)
    end

    --- parse a deep link payload from a /start message.
    -- @param message table the message object
    -- @return string|nil the deep link payload
    function api.parse_deep_link(message)
        if type(message) ~= 'table' or not message.text then
            return nil
        end
        return message.text:match('^/start%s+(.+)$')
    end

    --- build a paginated inline keyboard with navigation buttons.
    -- @param items table array of items to paginate
    -- @param page number current page number (default 1)
    -- @param items_per_page number items per page (default 5)
    -- @param callback_prefix string callback data prefix (default 'page')
    -- @return table pagination result with items, page, total_pages, nav_row
    function api.paginate(items, page, items_per_page, callback_prefix)
        page = page or 1
        items_per_page = items_per_page or 5
        callback_prefix = callback_prefix or 'page'
        local total_pages = math.ceil(#items / items_per_page)
        if total_pages < 1 then total_pages = 1 end
        if page < 1 then page = 1 end
        if page > total_pages then page = total_pages end
        local start_idx = (page - 1) * items_per_page + 1
        local end_idx = math.min(start_idx + items_per_page - 1, #items)
        local page_items = {}
        for i = start_idx, end_idx do
            page_items[#page_items + 1] = items[i]
        end
        local nav_row = api.row()
        if page > 1 then
            nav_row:callback_data_button(tools.symbols.previous .. ' Prev', callback_prefix .. ':' .. (page - 1))
        end
        nav_row:callback_data_button(page .. '/' .. total_pages, callback_prefix .. ':current')
        if page < total_pages then
            nav_row:callback_data_button('Next ' .. tools.symbols.next, callback_prefix .. ':' .. (page + 1))
        end
        return {
            items = page_items,
            page = page,
            total_pages = total_pages,
            nav_row = nav_row,
            has_prev = page > 1,
            has_next = page < total_pages
        }
    end

    --- parse a pagination callback data string to extract the page number.
    -- @param data string the callback data string
    -- @param callback_prefix string the prefix used in paginate (default 'page')
    -- @return number|nil the page number
    function api.parse_page_callback(data, callback_prefix)
        callback_prefix = callback_prefix or 'page'
        -- paginate builds callback data by plain concatenation, so the prefix
        -- must be matched literally, not as a lua pattern.
        local escaped_prefix = callback_prefix:gsub('(%W)', '%%%1')
        local page = data:match('^' .. escaped_prefix .. ':(%d+)$')
        return page and tonumber(page) or nil
    end

    --- safely call a function with error handling via pcall.
    -- @param fn function the function to call
    -- @param ... any arguments to pass to fn
    -- @return any result from the function, or false and error on failure
    function api.safe_call(fn, ...)
        local ok, result, extra = pcall(fn, ...)
        if not ok then
            return false, nil, result
        end
        return result, extra
    end

    --- send a typing indicator to a chat.
    -- @param chat_id number|string the target chat ID
    -- @return table API response
    function api.send_typing(chat_id)
        return api.send_chat_action(chat_id, 'typing')
    end

    --- check if a message is a bot command.
    -- @param message table the message object
    -- @return boolean true if the message starts with /, !, or #
    function api.is_command(message)
        if type(message) ~= 'table' then
            return false
        end
        local text = message.text or message.caption
        if not text then
            return false
        end
        return text:match('^[/!#]%w') ~= nil
    end

    --- check if a message is a reply to another message.
    -- @param message table the message object
    -- @return boolean true if the message is a reply
    function api.is_reply(message)
        if type(message) ~= 'table' then
            return false
        end
        return message.reply_to_message ~= nil
    end

    --- check if a message is from a private chat.
    -- @param message table the message object
    -- @return boolean true if the chat type is 'private'
    function api.is_private(message)
        if type(message) ~= 'table' or not message.chat then
            return false
        end
        return message.chat.type == 'private'
    end

    --- check if a message is from a group or supergroup.
    -- @param message table the message object
    -- @return boolean true if the chat type is 'group' or 'supergroup'
    function api.is_group(message)
        if type(message) ~= 'table' or not message.chat then
            return false
        end
        return message.chat.type == 'group' or message.chat.type == 'supergroup'
    end

    --- get the display name for a user object.
    -- @param user table the user object
    -- @return string the user's full name, or 'Unknown'
    function api.get_name(user)
        if type(user) ~= 'table' then
            return 'Unknown'
        end
        local name = user.first_name or ''
        if user.last_name then
            name = name .. ' ' .. user.last_name
        end
        return name
    end

    --- encode callback data as "action:key1=val1;key2=val2".
    -- @param action string the action identifier
    -- @param data table key-value pairs to encode
    -- @return string the encoded callback data string
    function api.encode_callback(action, data)
        if not data or not next(data) then
            return action
        end
        local parts = {}
        for k, v in pairs(data) do
            parts[#parts + 1] = tostring(k) .. '=' .. tostring(v)
        end
        table.sort(parts)
        return action .. ':' .. table.concat(parts, ';')
    end

    --- decode a callback data string back to action and key-value pairs.
    -- @param str string the callback data string
    -- @return table|nil table with action and data fields, or nil
    function api.decode_callback(str)
        if type(str) ~= 'string' then
            return nil
        end
        local action, rest = str:match('^([^:]+):?(.*)$')
        if not action then
            return nil
        end
        local data = {}
        if rest and rest ~= '' then
            for pair in rest:gmatch('[^;]+') do
                local k, v = pair:match('^([^=]+)=(.+)$')
                if k then
                    data[k] = tonumber(v) or v
                end
            end
        end
        return { action = action, data = data }
    end
end
