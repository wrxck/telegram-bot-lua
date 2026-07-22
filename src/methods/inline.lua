--- inline API methods.
-- @module telegram-bot-lua.methods.inline
return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    --- send answers to an inline query.
    -- @param inline_query_id string unique identifier for the answered query
    -- @param results string|table JSON-serialised array of InlineQueryResult or a table thereof
    -- @param opts table optional parameters (cache_time, is_personal, next_offset, button)
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.answer_inline_query(inline_query_id, results, opts)
        opts = opts or {}
        local button = opts.button
        button = api._json_enc(button)
        if results and type(results) == 'table' then
            if results.id then
                results = {results}
            end
            results = json.encode(results)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/answerInlineQuery', {
            ['inline_query_id'] = inline_query_id,
            ['results'] = results,
            ['cache_time'] = opts.cache_time,
            ['is_personal'] = opts.is_personal,
            ['next_offset'] = opts.next_offset,
            ['button'] = button
        })
        return success, res
    end

    --- set the result of an interaction with a web app and send a message on behalf of the user.
    -- @param web_app_query_id string unique identifier for the query to be answered
    -- @param result string|table an InlineQueryResult object describing the message to send
    -- @return table|false the sent message, or false on failure
    -- @return string|table the HTTP status or error details
    function api.answer_web_app_query(web_app_query_id, result)
        result = api._json_enc(result)
        local success, res = api.request(config.endpoint .. api.token .. '/answerWebAppQuery', {
            ['web_app_query_id'] = web_app_query_id,
            ['result'] = result
        })
        return success, res
    end

    --- answer a guest query with a single inline result (Bot API 10.0).
    -- @param guest_query_id string unique identifier for the query to be answered
    -- @param result string|table an InlineQueryResult object describing the message to send
    -- @return table|false the sent message, or false on failure
    -- @return string|table the HTTP status or error details
    function api.answer_guest_query(guest_query_id, result)
        result = api._json_enc(result)
        local success, res = api.request(config.endpoint .. api.token .. '/answerGuestQuery', {
            ['guest_query_id'] = guest_query_id,
            ['result'] = result
        })
        return success, res
    end

    --- send answers to callback queries sent from inline keyboards.
    -- @param callback_query_id string unique identifier for the query to be answered
    -- @param opts table optional parameters (text, show_alert, url, cache_time)
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.answer_callback_query(callback_query_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/answerCallbackQuery', {
            ['callback_query_id'] = callback_query_id,
            ['text'] = opts.text,
            ['show_alert'] = opts.show_alert,
            ['url'] = opts.url,
            ['cache_time'] = opts.cache_time
        })
        return success, res
    end

    -- Convenience helpers for common inline patterns

    --- convenience helper to answer an inline query with a single article result.
    -- @param inline_query_id string unique identifier for the answered query
    -- @param title string title of the article
    -- @param description string short description of the result
    -- @param message_text string text of the message to be sent
    -- @param parse_mode string|boolean parse mode for the message text (true for MarkdownV2)
    -- @param reply_markup table an InlineKeyboardMarkup object
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.send_inline_article(inline_query_id, title, description, message_text, parse_mode, reply_markup)
        description = description or title
        message_text = message_text or description
        parse_mode = (type(parse_mode) == 'boolean' and parse_mode == true) and 'MarkdownV2' or parse_mode
        return api.answer_inline_query(inline_query_id, json.encode({{
            ['type'] = 'article',
            ['id'] = '1',
            ['title'] = title,
            ['description'] = description,
            ['input_message_content'] = {
                ['message_text'] = message_text,
                ['parse_mode'] = parse_mode
            },
            ['reply_markup'] = reply_markup
        }}))
    end

    --- convenience helper to answer an inline query with a URL article result.
    -- @param inline_query_id string unique identifier for the answered query
    -- @param title string title of the article
    -- @param url string URL of the result
    -- @param hide_url boolean whether to hide the URL in the message
    -- @param input_message_content table content of the message to be sent
    -- @param reply_markup table an InlineKeyboardMarkup object
    -- @param id string|number optional custom result identifier (defaults to '1')
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.send_inline_article_url(inline_query_id, title, url, hide_url, input_message_content, reply_markup, id)
        return api.answer_inline_query(inline_query_id, json.encode({{
            ['type'] = 'article',
            ['id'] = tonumber(id) ~= nil and tostring(id) or '1',
            ['title'] = tostring(title),
            ['url'] = tostring(url),
            ['hide_url'] = hide_url or false,
            ['input_message_content'] = input_message_content,
            ['reply_markup'] = reply_markup
        }}))
    end

    --- convenience helper to answer an inline query with a photo result by URL.
    -- @param inline_query_id string unique identifier for the answered query
    -- @param photo_url string a valid URL of the photo
    -- @param caption string caption for the photo
    -- @param reply_markup table an InlineKeyboardMarkup object
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.send_inline_photo(inline_query_id, photo_url, caption, reply_markup)
        return api.answer_inline_query(inline_query_id, json.encode({{
            ['type'] = 'photo',
            ['id'] = '1',
            ['photo_url'] = photo_url,
            ['thumbnail_url'] = photo_url,
            ['caption'] = caption,
            ['reply_markup'] = reply_markup
        }}))
    end

    --- convenience helper to answer an inline query with a cached photo result.
    -- @param inline_query_id string unique identifier for the answered query
    -- @param photo_file_id string file identifier of a previously uploaded photo
    -- @param caption string caption for the photo
    -- @param reply_markup table an InlineKeyboardMarkup object
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.send_inline_cached_photo(inline_query_id, photo_file_id, caption, reply_markup)
        return api.answer_inline_query(inline_query_id, json.encode({{
            ['type'] = 'photo',
            ['id'] = '1',
            ['photo_file_id'] = photo_file_id,
            ['caption'] = caption,
            ['reply_markup'] = reply_markup
        }}))
    end

    --- store a message that can be sent by a user of a mini app.
    -- @param user_id number unique identifier of the target user that can use the prepared message
    -- @param result string|table a JSON-serialised InlineQueryResult describing the message to be sent
    -- @param opts table optional parameters
    -- @param opts.allow_user_chats boolean pass true if the message can be sent to private chats with users
    -- @param opts.allow_bot_chats boolean pass true if the message can be sent to private chats with bots
    -- @param opts.allow_group_chats boolean pass true if the message can be sent to group and supergroup chats
    -- @param opts.allow_channel_chats boolean pass true if the message can be sent to channel chats
    -- @return table|false the prepared inline message, or false on failure
    -- @return string|table the HTTP status or error details
    function api.save_prepared_inline_message(user_id, result, opts)
        opts = opts or {}
        result = api._json_enc(result)
        local success, res = api.request(config.endpoint .. api.token .. '/savePreparedInlineMessage', {
            ['user_id'] = user_id,
            ['result'] = result,
            ['allow_user_chats'] = opts.allow_user_chats,
            ['allow_bot_chats'] = opts.allow_bot_chats,
            ['allow_group_chats'] = opts.allow_group_chats,
            ['allow_channel_chats'] = opts.allow_channel_chats
        })
        return success, res
    end
end
