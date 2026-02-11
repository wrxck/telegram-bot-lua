return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.send_game(chat_id, game_short_name, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendGame', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['game_short_name'] = game_short_name,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    function api.set_game_score(user_id, score, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setGameScore', {
            ['user_id'] = user_id,
            ['score'] = score,
            ['force'] = opts.force,
            ['disable_edit_message'] = opts.disable_edit_message,
            ['chat_id'] = opts.chat_id,
            ['message_id'] = opts.message_id,
            ['inline_message_id'] = opts.inline_message_id
        })
        return success, res
    end

    function api.get_game_high_scores(user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getGameHighScores', {
            ['user_id'] = user_id,
            ['chat_id'] = opts.chat_id,
            ['message_id'] = opts.message_id,
            ['inline_message_id'] = opts.inline_message_id
        })
        return success, res
    end
end
