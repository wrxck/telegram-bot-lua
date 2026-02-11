return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.send_sticker(chat_id, sticker, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendSticker', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['emoji'] = opts.emoji,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
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

    function api.get_sticker_set(name)
        local success, res = api.request(config.endpoint .. api.token .. '/getStickerSet', {
            ['name'] = name
        })
        return success, res
    end

    function api.get_custom_emoji_stickers(custom_emoji_ids)
        custom_emoji_ids = type(custom_emoji_ids) == 'table' and json.encode(custom_emoji_ids) or custom_emoji_ids
        local success, res = api.request(config.endpoint .. api.token .. '/getCustomEmojiStickers', {
            ['custom_emoji_ids'] = custom_emoji_ids
        })
        return success, res
    end

    function api.upload_sticker_file(user_id, sticker, sticker_format)
        local success, res = api.request(config.endpoint .. api.token .. '/uploadStickerFile', {
            ['user_id'] = user_id,
            ['sticker_format'] = sticker_format
        }, {
            ['sticker'] = sticker
        })
        return success, res
    end

    function api.create_new_sticker_set(user_id, name, title, stickers, opts)
        opts = opts or {}
        stickers = type(stickers) == 'table' and json.encode(stickers) or stickers
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

    function api.add_sticker_to_set(user_id, name, sticker)
        sticker = type(sticker) == 'table' and json.encode(sticker) or sticker
        local success, res = api.request(config.endpoint .. api.token .. '/addStickerToSet', {
            ['user_id'] = user_id,
            ['name'] = name,
            ['sticker'] = sticker
        })
        return success, res
    end

    function api.set_sticker_position_in_set(sticker, position)
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerPositionInSet', {
            ['sticker'] = sticker,
            ['position'] = position
        })
        return success, res
    end

    function api.delete_sticker_from_set(sticker)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteStickerFromSet', {
            ['sticker'] = sticker
        })
        return success, res
    end

    function api.replace_sticker_in_set(user_id, name, old_sticker, sticker)
        sticker = type(sticker) == 'table' and json.encode(sticker) or sticker
        local success, res = api.request(config.endpoint .. api.token .. '/replaceStickerInSet', {
            ['user_id'] = user_id,
            ['name'] = name,
            ['old_sticker'] = old_sticker,
            ['sticker'] = sticker
        })
        return success, res
    end

    function api.set_sticker_emoji_list(sticker, emoji_list)
        emoji_list = type(emoji_list) == 'table' and json.encode(emoji_list) or emoji_list
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerEmojiList', {
            ['sticker'] = sticker,
            ['emoji_list'] = emoji_list
        })
        return success, res
    end

    function api.set_sticker_keywords(sticker, keywords)
        keywords = type(keywords) == 'table' and json.encode(keywords) or keywords
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerKeywords', {
            ['sticker'] = sticker,
            ['keywords'] = keywords
        })
        return success, res
    end

    function api.set_sticker_mask_position(sticker, mask_position)
        mask_position = type(mask_position) == 'table' and json.encode(mask_position) or mask_position
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerMaskPosition', {
            ['sticker'] = sticker,
            ['mask_position'] = mask_position
        })
        return success, res
    end

    function api.set_sticker_set_title(name, title)
        title = tostring(title)
        if title:len() > 64 then
            title = title:sub(1, 64)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/setStickerSetTitle', {
            ['name'] = name,
            ['title'] = title
        })
        return success, res
    end

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

    function api.set_custom_emoji_sticker_set_thumbnail(name, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setCustomEmojiStickerSetThumbnail', {
            ['name'] = name,
            ['custom_emoji_id'] = opts.custom_emoji_id
        })
        return success, res
    end

    function api.delete_sticker_set(name)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteStickerSet', {
            ['name'] = name
        })
        return success, res
    end
end
