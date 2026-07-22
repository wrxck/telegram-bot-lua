--- stickers API methods.
-- @module telegram-bot-lua.methods.stickers
return function(api)
    local config = require('telegram-bot-lua.config')

    --- send a static, animated, or video sticker.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param sticker string sticker to send (file_id, HTTP URL, or file upload)
    -- @param opts table optional parameters
    -- @param opts.message_thread_id number unique identifier for the target message thread
    -- @param opts.emoji string emoji associated with the sticker
    -- @param opts.disable_notification boolean sends the message silently
    -- @param opts.reply_parameters table|string description of the message to reply to
    -- @param opts.reply_markup table|string additional interface options
    -- @return table,number the response object and HTTP status
    function api.send_sticker(chat_id, sticker, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = api._json_enc(reply_parameters)
        local reply_markup = opts.reply_markup
        reply_markup = api._json_enc(reply_markup)
        local success, res = api.request(config.endpoint .. api.token .. '/sendSticker', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['emoji'] = opts.emoji,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = api._json_enc(opts.suggested_post_parameters),
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        }, {
            ['sticker'] = sticker
        })
        return success, res
    end

    --- get a sticker set by name.
    -- @param name string name of the sticker set
    -- @return table,number the response object and HTTP status
    function api.get_sticker_set(name)
        local success, res = api.request(config.endpoint .. api.token .. '/getStickerSet', {
            ['name'] = name
        })
        return success, res
    end

    --- get information about custom emoji stickers by their identifiers.
    -- @param custom_emoji_ids table|string a JSON-serialized list of custom emoji identifiers
    -- @return table,number the response object and HTTP status
    function api.get_custom_emoji_stickers(custom_emoji_ids)
        custom_emoji_ids = api._json_enc(custom_emoji_ids)
        local success, res = api.request(config.endpoint .. api.token .. '/getCustomEmojiStickers', {
            ['custom_emoji_ids'] = custom_emoji_ids
        })
        return success, res
    end

    --- upload a sticker file for later use in sticker sets.
    -- @param user_id number unique identifier of the sticker file owner
    -- @param sticker string the sticker file to upload
    -- @param sticker_format string format of the sticker (static, animated, video)
    -- @return table,number the response object and HTTP status
    function api.upload_sticker_file(user_id, sticker, sticker_format)
        local success, res = api.request(config.endpoint .. api.token .. '/uploadStickerFile', {
            ['user_id'] = user_id,
            ['sticker_format'] = sticker_format
        }, {
            ['sticker'] = sticker
        })
        return success, res
    end

    --- create a new sticker set owned by a user.
    -- @param user_id number unique identifier of the created sticker set owner
    -- @param name string short name of the sticker set
    -- @param title string sticker set title (1-64 characters)
    -- @param stickers table|string a JSON-serialized list of stickers to be added to the set
    -- @param opts table optional parameters
    -- @param opts.sticker_type string type of stickers in the set
    -- @param opts.needs_repainting boolean pass true if stickers need repainting to match emoji colour
    -- @return table,number the response object and HTTP status
    function api.create_new_sticker_set(user_id, name, title, stickers, opts)
        opts = opts or {}
        stickers = api._json_enc(stickers)
        local success, res = api.request(config.endpoint .. api.token .. '/createNewStickerSet', {
            ['user_id'] = user_id,
            ['name'] = name,
            ['title'] = title,
            ['stickers'] = stickers,
            ['sticker_type'] = opts.sticker_type,
            ['needs_repainting'] = opts.needs_repainting
        })
        return success, res
    end

    --- add a new sticker to a set created by the bot.
    -- @param user_id number unique identifier of the sticker set owner
    -- @param name string sticker set name
    -- @param sticker table|string a JSON-serialized object with information about the sticker
    -- @return table,number the response object and HTTP status
    function api.add_sticker_to_set(user_id, name, sticker)
        sticker = api._json_enc(sticker)
        local success, res = api.request(config.endpoint .. api.token .. '/addStickerToSet', {
            ['user_id'] = user_id,
            ['name'] = name,
            ['sticker'] = sticker
        })
        return success, res
    end

    --- move a sticker in a set created by the bot to a specific position.
    -- @param sticker string file identifier of the sticker
    -- @param position number new sticker position in the set (zero-based)
    -- @return table,number the response object and HTTP status
    function api.set_sticker_position_in_set(sticker, position)
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerPositionInSet', {
            ['sticker'] = sticker,
            ['position'] = position
        })
        return success, res
    end

    --- delete a sticker from a set created by the bot.
    -- @param sticker string file identifier of the sticker
    -- @return table,number the response object and HTTP status
    function api.delete_sticker_from_set(sticker)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteStickerFromSet', {
            ['sticker'] = sticker
        })
        return success, res
    end

    --- replace an existing sticker in a sticker set with a new one.
    -- @param user_id number unique identifier of the sticker set owner
    -- @param name string sticker set name
    -- @param old_sticker string file identifier of the sticker to be replaced
    -- @param sticker table|string a JSON-serialized object with information about the new sticker
    -- @return table,number the response object and HTTP status
    function api.replace_sticker_in_set(user_id, name, old_sticker, sticker)
        sticker = api._json_enc(sticker)
        local success, res = api.request(config.endpoint .. api.token .. '/replaceStickerInSet', {
            ['user_id'] = user_id,
            ['name'] = name,
            ['old_sticker'] = old_sticker,
            ['sticker'] = sticker
        })
        return success, res
    end

    --- change the list of emoji assigned to a regular or custom emoji sticker.
    -- @param sticker string file identifier of the sticker
    -- @param emoji_list table|string a JSON-serialized list of 1-20 emoji associated with the sticker
    -- @return table,number the response object and HTTP status
    function api.set_sticker_emoji_list(sticker, emoji_list)
        emoji_list = api._json_enc(emoji_list)
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerEmojiList', {
            ['sticker'] = sticker,
            ['emoji_list'] = emoji_list
        })
        return success, res
    end

    --- change search keywords assigned to a regular or custom emoji sticker.
    -- @param sticker string file identifier of the sticker
    -- @param keywords table|string a JSON-serialized list of 0-20 search keywords
    -- @return table,number the response object and HTTP status
    function api.set_sticker_keywords(sticker, keywords)
        keywords = api._json_enc(keywords)
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerKeywords', {
            ['sticker'] = sticker,
            ['keywords'] = keywords
        })
        return success, res
    end

    --- change the mask position of a mask sticker.
    -- @param sticker string file identifier of the sticker
    -- @param mask_position table|string a JSON-serialized object with the position where the mask should be placed
    -- @return table,number the response object and HTTP status
    function api.set_sticker_mask_position(sticker, mask_position)
        mask_position = api._json_enc(mask_position)
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerMaskPosition', {
            ['sticker'] = sticker,
            ['mask_position'] = mask_position
        })
        return success, res
    end

    --- set the title of a created sticker set. truncated to 64 characters.
    -- @param name string sticker set name
    -- @param title string sticker set title (max 64 characters)
    -- @return table,number the response object and HTTP status
    function api.set_sticker_set_title(name, title)
        title = api._truncate(title, 64)
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerSetTitle', {
            ['name'] = name,
            ['title'] = title
        })
        return success, res
    end

    --- set the thumbnail of a regular or mask sticker set.
    -- @param name string sticker set name
    -- @param user_id number unique identifier of the sticker set owner
    -- @param opts table optional parameters
    -- @param opts.thumbnail string thumbnail file (file upload)
    -- @param opts.format string format of the thumbnail
    -- @return table,number the response object and HTTP status
    function api.set_sticker_set_thumbnail(name, user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerSetThumbnail', {
            ['name'] = name,
            ['user_id'] = user_id,
            ['format'] = opts.format
        }, {
            ['thumbnail'] = opts.thumbnail
        })
        return success, res
    end

    --- set the thumbnail of a custom emoji sticker set.
    -- @param name string sticker set name
    -- @param opts table optional parameters
    -- @param opts.custom_emoji_id string custom emoji identifier of a sticker from the set to use as the thumbnail
    -- @return table,number the response object and HTTP status
    function api.set_custom_emoji_sticker_set_thumbnail(name, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setCustomEmojiStickerSetThumbnail', {
            ['name'] = name,
            ['custom_emoji_id'] = opts.custom_emoji_id
        })
        return success, res
    end

    --- delete a sticker set that was created by the bot.
    -- @param name string sticker set name
    -- @return table,number the response object and HTTP status
    function api.delete_sticker_set(name)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteStickerSet', {
            ['name'] = name
        })
        return success, res
    end
end
