return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.answer_inline_query(inline_query_id, results, opts)
        opts = opts or {}
        local button = opts.button
        button = type(button) == 'table' and json.encode(button) or button
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

    function api.answer_web_app_query(web_app_query_id, result)
        result = type(result) == 'table' and json.encode(result) or result
        local success, res = api.request(config.endpoint .. api.token .. '/answerWebAppQuery', {
            ['web_app_query_id'] = web_app_query_id,
            ['result'] = result
        })
        return success, res
    end

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

    function api.send_inline_article(inline_query_id, title, description, message_text, parse_mode, reply_markup)
        description = description or title
        message_text = message_text or description
        parse_mode = (type(parse_mode) == 'boolean' and parse_mode == true) and 'markdown' or parse_mode
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

    function api.send_inline_cached_photo(inline_query_id, photo_file_id, caption, reply_markup)
        return api.answer_inline_query(inline_query_id, json.encode({{
            ['type'] = 'photo',
            ['id'] = '1',
            ['photo_file_id'] = photo_file_id,
            ['caption'] = caption,
            ['reply_markup'] = reply_markup
        }}))
    end
end
