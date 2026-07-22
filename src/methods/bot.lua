--- bot API methods.
-- @module telegram-bot-lua.methods.bot
return function(api)
    local config = require('telegram-bot-lua.config')

    --- get basic info about a file and prepare it for downloading.
    -- @param file_id string file identifier to get info about
    -- @return table,number the response object and HTTP status
    function api.get_file(file_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getFile', {
            ['file_id'] = file_id
        })
        return success, res
    end

    --- change the list of the bot's commands.
    -- @param commands table|string a JSON-serialized or encoded list of BotCommand
    -- @param opts table optional parameters
    -- @param opts.scope table|string a JSON-serialized scope of users for which commands are relevant
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.set_my_commands(commands, opts)
        opts = opts or {}
        commands = api._json_enc(commands)
        local scope = opts.scope
        scope = api._json_enc(scope)
        local success, res = api.request(config.endpoint .. api.token .. '/setMyCommands', {
            ['commands'] = commands,
            ['scope'] = scope,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- delete the list of the bot's commands for the given scope and language.
    -- @param opts table optional parameters
    -- @param opts.scope table|string a JSON-serialized scope of users for which commands are relevant
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.delete_my_commands(opts)
        opts = opts or {}
        local scope = opts.scope
        scope = api._json_enc(scope)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteMyCommands', {
            ['scope'] = scope,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- get the current list of the bot's commands for the given scope and language.
    -- @param opts table optional parameters
    -- @param opts.scope table|string a JSON-serialized scope of users for which commands are relevant
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.get_my_commands(opts)
        opts = opts or {}
        local scope = opts.scope
        scope = api._json_enc(scope)
        local success, res = api.request(config.endpoint .. api.token .. '/getMyCommands', {
            ['scope'] = scope,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- change the bot's name. truncated to 64 characters.
    -- @param name string new bot name (max 64 characters)
    -- @param opts table optional parameters
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.set_my_name(name, opts)
        opts = opts or {}
        name = api._truncate(name, 64)
        local success, res = api.request(config.endpoint .. api.token .. '/setMyName', {
            ['name'] = name,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- get the current bot name for the given language.
    -- @param opts table optional parameters
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.get_my_name(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getMyName', {
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- change the bot's description. truncated to 512 characters.
    -- @param description string new bot description (max 512 characters)
    -- @param opts table optional parameters
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.set_my_description(description, opts)
        opts = opts or {}
        description = api._truncate(description, 512)
        local success, res = api.request(config.endpoint .. api.token .. '/setMyDescription', {
            ['description'] = description,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- get the current bot description for the given language.
    -- @param opts table optional parameters
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.get_my_description(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getMyDescription', {
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- change the bot's short description. truncated to 120 characters.
    -- @param short_description string new short description (max 120 characters)
    -- @param opts table optional parameters
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.set_my_short_description(short_description, opts)
        opts = opts or {}
        short_description = api._truncate(short_description, 120)
        local success, res = api.request(config.endpoint .. api.token .. '/setMyShortDescription', {
            ['short_description'] = short_description,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- get the current bot short description for the given language.
    -- @param opts table optional parameters
    -- @param opts.language_code string a two-letter ISO 639-1 language code
    -- @return table,number the response object and HTTP status
    function api.get_my_short_description(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getMyShortDescription', {
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    --- change the bot's menu button in a private chat or the default menu button.
    -- @param opts table optional parameters
    -- @param opts.chat_id number|string unique identifier for the target private chat
    -- @param opts.menu_button table|string a JSON-serialized object for the bot's new menu button
    -- @return table,number the response object and HTTP status
    function api.set_chat_menu_button(opts)
        opts = opts or {}
        local menu_button = opts.menu_button
        menu_button = api._json_enc(menu_button)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatMenuButton', {
            ['chat_id'] = opts.chat_id,
            ['menu_button'] = menu_button
        })
        return success, res
    end

    --- get the current value of the bot's menu button in a private chat or the default menu button.
    -- @param opts table optional parameters
    -- @param opts.chat_id number|string unique identifier for the target private chat
    -- @return table,number the response object and HTTP status
    function api.get_chat_menu_button(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getChatMenuButton', {
            ['chat_id'] = opts.chat_id
        })
        return success, res
    end

    --- change the default administrator rights requested by the bot when it's added to groups or channels.
    -- @param opts table optional parameters
    -- @param opts.rights table|string a JSON-serialized object describing new default administrator rights
    -- @param opts.for_channels boolean pass true to change the default rights for channels
    -- @return table,number the response object and HTTP status
    function api.set_my_default_administrator_rights(opts)
        opts = opts or {}
        local rights = opts.rights
        rights = api._json_enc(rights)
        local success, res = api.request(config.endpoint .. api.token .. '/setMyDefaultAdministratorRights', {
            ['rights'] = rights,
            ['for_channels'] = opts.for_channels
        })
        return success, res
    end

    --- get the current default administrator rights of the bot.
    -- @param opts table optional parameters
    -- @param opts.for_channels boolean pass true to get the default rights for channels
    -- @return table,number the response object and HTTP status
    function api.get_my_default_administrator_rights(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getMyDefaultAdministratorRights', {
            ['for_channels'] = opts.for_channels
        })
        return success, res
    end

    --- set the bot's profile photo.
    -- @param opts table optional parameters
    -- @param opts.photo string the photo to set as the bot's profile photo (file upload)
    -- @param opts.is_public boolean pass true to set the public photo
    -- @return table,number the response object and HTTP status
    function api.set_my_profile_photo(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setMyProfilePhoto', {
            ['is_public'] = opts.is_public
        }, {
            ['photo'] = opts.photo
        })
        return success, res
    end

    --- remove the bot's profile photo.
    -- @param opts table optional parameters
    -- @param opts.is_public boolean pass true to remove the public photo
    -- @return table,number the response object and HTTP status
    function api.remove_my_profile_photo(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/removeMyProfilePhoto', {
            ['is_public'] = opts.is_public
        })
        return success, res
    end

    --- get the token of a managed bot.
    -- @param user_id number unique identifier of the managed bot user
    -- @return table,number the response object and HTTP status
    function api.get_managed_bot_token(user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getManagedBotToken', {
            ['user_id'] = user_id
        })
        return success, res
    end

    --- replace the token of a managed bot with a new one.
    -- @param user_id number unique identifier of the managed bot user
    -- @return table,number the response object and HTTP status
    function api.replace_managed_bot_token(user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/replaceManagedBotToken', {
            ['user_id'] = user_id
        })
        return success, res
    end

    --- save a prepared keyboard button for later use.
    -- @param user_id number unique identifier of the target user
    -- @param button table|string a JSON-serialized keyboard button to save
    -- @return table,number the response object and HTTP status
    function api.save_prepared_keyboard_button(user_id, button)
        button = api._json_enc(button)
        local success, res = api.request(config.endpoint .. api.token .. '/savePreparedKeyboardButton', {
            ['user_id'] = user_id,
            ['button'] = button
        })
        return success, res
    end

    --- get the access settings of a managed bot (Bot API 10.0).
    -- @param user_id number user identifier of the managed bot
    -- @return table,number the response object and HTTP status
    function api.get_managed_bot_access_settings(user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getManagedBotAccessSettings', {
            ['user_id'] = user_id
        })
        return success, res
    end

    --- change the access settings of a managed bot (Bot API 10.0).
    -- @param user_id number user identifier of the managed bot
    -- @param is_access_restricted boolean true if only selected users can access the bot
    -- @param opts table optional parameters
    -- @param opts.added_user_ids table list of up to 10 user ids granted access in addition to the owner
    -- @return table,number the response object and HTTP status
    function api.set_managed_bot_access_settings(user_id, is_access_restricted, opts)
        opts = opts or {}
        local added_user_ids = opts.added_user_ids
        added_user_ids = api._json_enc(added_user_ids)
        local success, res = api.request(config.endpoint .. api.token .. '/setManagedBotAccessSettings', {
            ['user_id'] = user_id,
            ['is_access_restricted'] = is_access_restricted,
            ['added_user_ids'] = added_user_ids
        })
        return success, res
    end

    --- get recent messages from a user's personal chat (Bot API 10.0).
    -- @param user_id number unique identifier for the target user
    -- @param limit number maximum number of messages to return; 1-20
    -- @return table,number the response object and HTTP status
    function api.get_user_personal_chat_messages(user_id, limit)
        local success, res = api.request(config.endpoint .. api.token .. '/getUserPersonalChatMessages', {
            ['user_id'] = user_id,
            ['limit'] = limit
        })
        return success, res
    end

    --- verify a user on behalf of the organisation which is represented by the bot.
    -- @param user_id number unique identifier of the target user
    -- @param opts table optional parameters
    -- @param opts.custom_description string custom description for the verification; 0-70 characters
    -- @return table,number the response object and HTTP status
    function api.verify_user(user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/verifyUser', {
            ['user_id'] = user_id,
            ['custom_description'] = opts.custom_description
        })
        return success, res
    end

    --- verify a chat on behalf of the organisation which is represented by the bot.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param opts table optional parameters
    -- @param opts.custom_description string custom description for the verification; 0-70 characters
    -- @return table,number the response object and HTTP status
    function api.verify_chat(chat_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/verifyChat', {
            ['chat_id'] = chat_id,
            ['custom_description'] = opts.custom_description
        })
        return success, res
    end

    --- remove verification from a user who is currently verified on behalf of the organisation.
    -- @param user_id number unique identifier of the target user
    -- @return table,number the response object and HTTP status
    function api.remove_user_verification(user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/removeUserVerification', {
            ['user_id'] = user_id
        })
        return success, res
    end

    --- remove verification from a chat that is currently verified on behalf of the organisation.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @return table,number the response object and HTTP status
    function api.remove_chat_verification(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/removeChatVerification', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- change the emoji status for a given user that previously allowed the bot to manage their emoji status.
    -- @param user_id number unique identifier of the target user
    -- @param opts table optional parameters
    -- @param opts.emoji_status_custom_emoji_id string custom emoji identifier of the emoji status to set
    -- @param opts.emoji_status_expiration_date number expiration date of the emoji status, if any
    -- @return table,number the response object and HTTP status
    function api.set_user_emoji_status(user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setUserEmojiStatus', {
            ['user_id'] = user_id,
            ['emoji_status_custom_emoji_id'] = opts.emoji_status_custom_emoji_id,
            ['emoji_status_expiration_date'] = opts.emoji_status_expiration_date
        })
        return success, res
    end
end
