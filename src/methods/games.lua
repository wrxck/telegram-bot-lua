--- games API methods.
-- @module telegram-bot-lua.methods.games
return function(api)
    local config = require('telegram-bot-lua.config')

    --- send a game to a chat.
    -- @param chat_id number unique identifier for the target chat
    -- @param game_short_name string short name of the game
    -- @param opts table optional parameters (message_thread_id, disable_notification, protect_content, reply_parameters, reply_markup, etc.)
    -- @return table|false the sent message, or false on failure
    -- @return string|table the HTTP status or error details
    function api.send_game(chat_id, game_short_name, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = api._json_enc(reply_parameters)
        local reply_markup = opts.reply_markup
        reply_markup = api._json_enc(reply_markup)
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

    --- set the score of the specified user in a game.
    -- @param user_id number identifier of the target user
    -- @param score number new score, must be non-negative
    -- @param opts table optional parameters (force, disable_edit_message, chat_id, message_id, inline_message_id)
    -- @return table|false the edited message or true on success, or false on failure
    -- @return string|table the HTTP status or error details
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

    --- get high score data for a game.
    -- @param user_id number identifier of the target user
    -- @param opts table optional parameters (chat_id, message_id, inline_message_id)
    -- @return table|false array of GameHighScore objects, or false on failure
    -- @return string|table the HTTP status or error details
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
