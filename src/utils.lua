return function(api)
    local tools = require('telegram-bot-lua.tools')

    -- Text formatting helpers for different parse modes.
    -- Usage: api.fmt.bold('text', 'HTML') => '<b>text</b>'

    api.fmt = {}

    function api.fmt.bold(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<b>' .. tools.escape_html(text) .. '</b>'
        elseif parse_mode:lower() == 'markdownv2' then
            return '*' .. tools.escape_markdown_v2(text) .. '*'
        end
        return '*' .. tools.escape_markdown(text) .. '*'
    end

    function api.fmt.italic(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<i>' .. tools.escape_html(text) .. '</i>'
        elseif parse_mode:lower() == 'markdownv2' then
            return '_' .. tools.escape_markdown_v2(text) .. '_'
        end
        return '_' .. tools.escape_markdown(text) .. '_'
    end

    function api.fmt.code(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<code>' .. tools.escape_html(text) .. '</code>'
        end
        return '`' .. text .. '`'
    end

    function api.fmt.pre(text, language, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            if language then
                return '<pre><code class="language-' .. tools.escape_html(language) .. '">' .. tools.escape_html(text) .. '</code></pre>'
            end
            return '<pre>' .. tools.escape_html(text) .. '</pre>'
        end
        local fence = '```'
        return fence .. (language or '') .. '\n' .. text .. '\n' .. fence
    end

    function api.fmt.link(text, url, parse_mode)
        return tools.create_link(text, url, parse_mode or 'HTML')
    end

    function api.fmt.mention(user_id, name, parse_mode)
        return tools.get_formatted_user(user_id, name, parse_mode or 'HTML')
    end

    function api.fmt.spoiler(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<tg-spoiler>' .. tools.escape_html(text) .. '</tg-spoiler>'
        end
        return '||' .. tools.escape_markdown_v2(text) .. '||'
    end

    function api.fmt.strikethrough(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<s>' .. tools.escape_html(text) .. '</s>'
        end
        return '~' .. tools.escape_markdown_v2(text) .. '~'
    end

    function api.fmt.underline(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<u>' .. tools.escape_html(text) .. '</u>'
        end
        return '__' .. tools.escape_markdown_v2(text) .. '__'
    end

    function api.fmt.blockquote(text, parse_mode)
        parse_mode = parse_mode or 'HTML'
        if parse_mode:lower() == 'html' then
            return '<blockquote>' .. tools.escape_html(text) .. '</blockquote>'
        end
        local lines = {}
        for line in (text .. '\n'):gmatch('(.-)\n') do
            lines[#lines + 1] = '>' .. line
        end
        return table.concat(lines, '\n')
    end

    -- Command parsing: extract command, args, and bot username from a message.

    function api.extract_command(message)
        if type(message) ~= 'table' then
            return false
        end
        local text = message.text or message.caption
        if not text then
            return false
        end
        local cmd, bot_username = text:match('^[/!#](%w+)@(%w+)')
        if not cmd then
            cmd = text:match('^[/!#](%w+)')
        end
        if not cmd then
            return false
        end
        local args_str = text:match('^[/!#]%w+@?%w*%s+(.+)$')
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

    -- Get the text content of any message (text or caption).

    function api.get_text(message)
        if type(message) ~= 'table' then
            return nil
        end
        return message.text or message.caption
    end

    -- Get the sender's user ID from any update type.

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

    -- Get the chat ID from any update type.

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

    -- Deep link helpers.

    function api.deep_link(bot_username, payload)
        return 'https://t.me/' .. bot_username .. '?start=' .. tostring(payload)
    end

    function api.deep_link_group(bot_username, payload)
        return 'https://t.me/' .. bot_username .. '?startgroup=' .. tostring(payload)
    end

    function api.parse_deep_link(message)
        if type(message) ~= 'table' or not message.text then
            return nil
        end
        return message.text:match('^/start%s+(.+)$')
    end

    -- Paginated inline keyboard builder.
    -- Returns an inline keyboard with items and prev/next navigation buttons.

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

    -- Parse a pagination callback: returns page number or nil.

    function api.parse_page_callback(data, callback_prefix)
        callback_prefix = callback_prefix or 'page'
        local page = data:match('^' .. callback_prefix .. ':(%d+)$')
        return page and tonumber(page) or nil
    end

    -- Safe message send with error handling.
    -- Wraps api calls in pcall and returns success, result, error.

    function api.safe_call(fn, ...)
        local ok, result, extra = pcall(fn, ...)
        if not ok then
            return false, nil, result
        end
        return result, extra
    end

    -- Convenience: send typing indicator.

    function api.send_typing(chat_id)
        return api.send_chat_action(chat_id, 'typing')
    end

    -- Check if a message is a command.

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

    -- Check if a message is a reply.

    function api.is_reply(message)
        if type(message) ~= 'table' then
            return false
        end
        return message.reply_to_message ~= nil
    end

    -- Check if the message is from a private chat.

    function api.is_private(message)
        if type(message) ~= 'table' or not message.chat then
            return false
        end
        return message.chat.type == 'private'
    end

    -- Check if the message is from a group or supergroup.

    function api.is_group(message)
        if type(message) ~= 'table' or not message.chat then
            return false
        end
        return message.chat.type == 'group' or message.chat.type == 'supergroup'
    end

    -- Get display name for a user object.

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

    -- Build a callback data string (for inline buttons) with key-value pairs.
    -- Encodes as "action:key1=val1;key2=val2"

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

    -- Parse a callback data string back to action and key-value pairs.

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
