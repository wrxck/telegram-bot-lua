-- Legacy compatibility layer for v2 -> v3 migration
-- Provides deprecated method names and require('telegram-bot-lua.core') support
return function(api)
    local warned = {}
    local function deprecation_warning(old_name, new_name)
        if not warned[old_name] then
            io.stderr:write(string.format(
                '[telegram-bot-lua] DEPRECATED: %s is deprecated, use %s instead\n',
                old_name, new_name
            ))
            warned[old_name] = true
        end
    end

    -- v2: get_chat_members_count -> v3: get_chat_member_count
    function api.get_chat_members_count(chat_id)
        deprecation_warning('get_chat_members_count', 'get_chat_member_count')
        return api.get_chat_member_count(chat_id)
    end

    -- v2: kick_chat_member -> v3: ban_chat_member
    function api.kick_chat_member(chat_id, user_id, until_date)
        deprecation_warning('kick_chat_member', 'ban_chat_member')
        return api.ban_chat_member(chat_id, user_id, { until_date = until_date })
    end

    -- v2 positional-arg wrappers for commonly used methods

    -- v2: send_message(chat_id, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup)
    local v3_send_message = api.send_message
    function api.send_message(chat_id, text, opts_or_parse_mode, ...)
        if type(opts_or_parse_mode) == 'string' or type(opts_or_parse_mode) == 'boolean' then
            deprecation_warning('send_message(positional args)', 'send_message(chat_id, text, opts)')
            local parse_mode = opts_or_parse_mode
            local args = {...}
            local disable_web_page_preview = args[1]
            local disable_notification = args[2]
            local reply_to_message_id = args[3]
            -- args[4..8] skipped (were nil placeholders)
            local reply_markup = args[4] or args[5] or args[6] or args[7] or args[8]
            local link_preview_options
            if disable_web_page_preview then
                link_preview_options = { is_disabled = true }
            end
            local reply_parameters
            if reply_to_message_id then
                reply_parameters = api.reply_parameters(reply_to_message_id)
            end
            return v3_send_message(chat_id, text, {
                parse_mode = parse_mode,
                link_preview_options = link_preview_options,
                disable_notification = disable_notification,
                reply_parameters = reply_parameters,
                reply_markup = reply_markup
            })
        end
        return v3_send_message(chat_id, text, opts_or_parse_mode)
    end

    -- v2: answer_callback_query(callback_query_id, text, show_alert, url, cache_time)
    local v3_answer_callback_query = api.answer_callback_query
    function api.answer_callback_query(callback_query_id, opts_or_text, ...)
        if type(opts_or_text) == 'string' then
            deprecation_warning('answer_callback_query(positional args)', 'answer_callback_query(id, opts)')
            local text = opts_or_text
            local args = {...}
            return v3_answer_callback_query(callback_query_id, {
                text = text,
                show_alert = args[1],
                url = args[2],
                cache_time = args[3]
            })
        end
        return v3_answer_callback_query(callback_query_id, opts_or_text)
    end

    -- v2: edit_message_text(chat_id, message_id, text, parse_mode, disable_web_page_preview, reply_markup, inline_message_id)
    local v3_edit_message_text = api.edit_message_text
    function api.edit_message_text(chat_id, message_id, text, opts_or_parse_mode, ...)
        if type(opts_or_parse_mode) == 'string' or type(opts_or_parse_mode) == 'boolean' then
            deprecation_warning('edit_message_text(positional args)', 'edit_message_text(chat_id, message_id, text, opts)')
            local parse_mode = opts_or_parse_mode
            local args = {...}
            local disable_web_page_preview = args[1]
            local reply_markup = args[2]
            local inline_message_id = args[3]
            local link_preview_options
            if disable_web_page_preview then
                link_preview_options = { is_disabled = true }
            end
            return v3_edit_message_text(chat_id, message_id, text, {
                parse_mode = parse_mode,
                link_preview_options = link_preview_options,
                reply_markup = reply_markup,
                inline_message_id = inline_message_id
            })
        end
        return v3_edit_message_text(chat_id, message_id, text, opts_or_parse_mode)
    end
end
