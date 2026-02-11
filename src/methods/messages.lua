return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.send_message(chat_id, text, opts)
        opts = opts or {}
        local entities = opts.entities
        entities = type(entities) == 'table' and json.encode(entities) or entities
        local link_preview_options = opts.link_preview_options
        link_preview_options = type(link_preview_options) == 'table' and json.encode(link_preview_options) or link_preview_options
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        chat_id = (type(chat_id) == 'table' and chat_id.chat and chat_id.chat.id) and chat_id.chat.id or chat_id
        local parse_mode = opts.parse_mode
        parse_mode = (type(parse_mode) == 'boolean' and parse_mode == true) and 'MarkdownV2' or parse_mode
        local success, res = api.request(config.endpoint .. api.token .. '/sendMessage', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['entities'] = entities,
            ['link_preview_options'] = link_preview_options,
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

    function api.send_reply(message, text, opts)
        if type(message) ~= 'table' or not message.chat or not message.chat.id or not message.message_id then
            return false
        end
        opts = opts or {}
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local parse_mode = opts.parse_mode
        parse_mode = (type(parse_mode) == 'boolean' and parse_mode == true) and 'markdown' or parse_mode
        local reply_parameters = opts.reply_parameters
        if not reply_parameters then
            reply_parameters = api.reply_parameters(message.message_id, message.chat.id, true, nil, parse_mode, nil, nil)
        end
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local entities = opts.entities
        entities = type(entities) == 'table' and json.encode(entities) or entities
        local link_preview_options = opts.link_preview_options
        link_preview_options = type(link_preview_options) == 'table' and json.encode(link_preview_options) or link_preview_options
        local success, res = api.request(config.endpoint .. api.token .. '/sendMessage', {
            ['chat_id'] = message.chat.id,
            ['message_thread_id'] = opts.message_thread_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['entities'] = entities,
            ['link_preview_options'] = link_preview_options,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup
        })
        return success, res
    end

    function api.forward_message(chat_id, from_chat_id, message_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/forwardMessage', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['from_chat_id'] = from_chat_id,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['message_id'] = message_id
        })
        return success, res
    end

    function api.forward_messages(chat_id, from_chat_id, message_ids, opts)
        opts = opts or {}
        message_ids = type(message_ids) == 'table' and json.encode(message_ids) or message_ids
        local success, res = api.request(config.endpoint .. api.token .. '/forwardMessages', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['from_chat_id'] = from_chat_id,
            ['message_ids'] = message_ids,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content
        })
        return success, res
    end

    function api.copy_message(chat_id, from_chat_id, message_id, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/copyMessage', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['from_chat_id'] = from_chat_id,
            ['message_id'] = message_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup
        })
        return success, res
    end

    function api.copy_messages(chat_id, from_chat_id, message_ids, opts)
        opts = opts or {}
        message_ids = type(message_ids) == 'table' and json.encode(message_ids) or message_ids
        local success, res = api.request(config.endpoint .. api.token .. '/copyMessages', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['from_chat_id'] = from_chat_id,
            ['message_ids'] = message_ids,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['remove_caption'] = opts.remove_caption
        })
        return success, res
    end

    function api.send_photo(chat_id, photo, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendPhoto', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['has_spoiler'] = opts.has_spoiler,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        }, {
            ['photo'] = photo
        })
        return success, res
    end

    function api.send_audio(chat_id, audio, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendAudio', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['duration'] = opts.duration,
            ['performer'] = opts.performer,
            ['title'] = opts.title,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        }, {
            ['audio'] = audio,
            ['thumbnail'] = opts.thumbnail
        })
        return success, res
    end

    function api.send_document(chat_id, document, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendDocument', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['disable_content_type_detection'] = opts.disable_content_type_detection,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        }, {
            ['document'] = document,
            ['thumbnail'] = opts.thumbnail
        })
        return success, res
    end

    function api.send_video(chat_id, video, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendVideo', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['duration'] = opts.duration,
            ['width'] = opts.width,
            ['height'] = opts.height,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['has_spoiler'] = opts.has_spoiler,
            ['supports_streaming'] = opts.supports_streaming,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        }, {
            ['video'] = video,
            ['thumbnail'] = opts.thumbnail
        })
        return success, res
    end

    function api.send_animation(chat_id, animation, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendAnimation', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['duration'] = opts.duration,
            ['width'] = opts.width,
            ['height'] = opts.height,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['has_spoiler'] = opts.has_spoiler,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        }, {
            ['animation'] = animation,
            ['thumbnail'] = opts.thumbnail
        })
        return success, res
    end

    function api.send_voice(chat_id, voice, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendVoice', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['duration'] = opts.duration,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        }, {
            ['voice'] = voice
        })
        return success, res
    end

    function api.send_video_note(chat_id, video_note, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendVideoNote', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['duration'] = opts.duration,
            ['length'] = opts.length,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        }, {
            ['video_note'] = video_note,
            ['thumbnail'] = opts.thumbnail
        })
        return success, res
    end

    function api.send_media_group(chat_id, media, opts)
        opts = opts or {}
        media = type(media) == 'table' and json.encode(media) or media
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local success, res = api.request(config.endpoint .. api.token .. '/sendMediaGroup', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['media'] = media,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    function api.send_location(chat_id, latitude, longitude, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendLocation', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['horizontal_accuracy'] = opts.horizontal_accuracy,
            ['live_period'] = opts.live_period,
            ['heading'] = opts.heading,
            ['proximity_alert_radius'] = opts.proximity_alert_radius,
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

    function api.send_venue(chat_id, latitude, longitude, title, address, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendVenue', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['title'] = title,
            ['address'] = address,
            ['foursquare_id'] = opts.foursquare_id,
            ['foursquare_type'] = opts.foursquare_type,
            ['google_place_id'] = opts.google_place_id,
            ['google_place_type'] = opts.google_place_type,
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

    function api.send_contact(chat_id, phone_number, first_name, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendContact', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['phone_number'] = phone_number,
            ['first_name'] = first_name,
            ['last_name'] = opts.last_name,
            ['vcard'] = opts.vcard,
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

    function api.send_poll(chat_id, question, options, opts)
        opts = opts or {}
        options = type(options) == 'table' and json.encode(options) or options
        local explanation_entities = opts.explanation_entities
        explanation_entities = type(explanation_entities) == 'table' and json.encode(explanation_entities) or explanation_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendPoll', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['question'] = question,
            ['options'] = options,
            ['is_anonymous'] = opts.is_anonymous,
            ['type'] = opts.poll_type,
            ['allows_multiple_answers'] = opts.allows_multiple_answers,
            ['correct_option_id'] = opts.correct_option_id,
            ['explanation'] = opts.explanation,
            ['explanation_parse_mode'] = opts.explanation_parse_mode,
            ['explanation_entities'] = explanation_entities,
            ['open_period'] = opts.open_period,
            ['close_date'] = opts.close_date,
            ['is_closed'] = opts.is_closed,
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

    function api.send_dice(chat_id, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendDice', {
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
        })
        return success, res
    end

    function api.send_chat_action(chat_id, action, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/sendChatAction', {
            ['chat_id'] = chat_id,
            ['action'] = action or 'typing',
            ['message_thread_id'] = opts.message_thread_id,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.set_message_reaction(chat_id, message_id, opts)
        opts = opts or {}
        local reaction = opts.reaction
        reaction = type(reaction) == 'table' and json.encode(reaction) or reaction
        local success, res = api.request(config.endpoint .. api.token .. '/setMessageReaction', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['reaction'] = reaction,
            ['is_big'] = opts.is_big
        })
        return success, res
    end

    function api.send_paid_media(chat_id, star_count, media, opts)
        opts = opts or {}
        media = type(media) == 'table' and json.encode(media) or media
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendPaidMedia', {
            ['chat_id'] = chat_id,
            ['star_count'] = star_count,
            ['media'] = media,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['payload'] = opts.payload
        })
        return success, res
    end

    -- Edit methods

    function api.edit_message_text(chat_id, message_id, text, opts)
        opts = opts or {}
        local entities = opts.entities
        entities = type(entities) == 'table' and json.encode(entities) or entities
        local link_preview_options = opts.link_preview_options
        link_preview_options = type(link_preview_options) == 'table' and json.encode(link_preview_options) or link_preview_options
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local parse_mode = opts.parse_mode
        parse_mode = (type(parse_mode) == 'boolean' and parse_mode == true) and 'MarkdownV2' or parse_mode
        local success, res = api.request(config.endpoint .. api.token .. '/editMessageText', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = opts.inline_message_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['entities'] = entities,
            ['link_preview_options'] = link_preview_options,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.edit_message_caption(chat_id, message_id, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local parse_mode = opts.parse_mode
        parse_mode = (type(parse_mode) == 'boolean' and parse_mode == true) and 'MarkdownV2' or parse_mode
        local success, res = api.request(config.endpoint .. api.token .. '/editMessageCaption', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = opts.inline_message_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.edit_message_media(chat_id, message_id, media, opts)
        opts = opts or {}
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        media = type(media) == 'table' and json.encode(media) or media
        local success, res = api.request(config.endpoint .. api.token .. '/editMessageMedia', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = opts.inline_message_id,
            ['media'] = media,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.edit_message_reply_markup(chat_id, message_id, opts)
        opts = opts or {}
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/editMessageReplyMarkup', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = opts.inline_message_id,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.edit_message_live_location(chat_id, message_id, latitude, longitude, opts)
        opts = opts or {}
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/editMessageLiveLocation', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = opts.inline_message_id,
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['live_period'] = opts.live_period,
            ['horizontal_accuracy'] = opts.horizontal_accuracy,
            ['heading'] = opts.heading,
            ['proximity_alert_radius'] = opts.proximity_alert_radius,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.stop_message_live_location(chat_id, message_id, opts)
        opts = opts or {}
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/stopMessageLiveLocation', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = opts.inline_message_id,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.stop_poll(chat_id, message_id, opts)
        opts = opts or {}
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/stopPoll', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.delete_message(chat_id, message_id)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteMessage', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id
        })
        return success, res
    end

    function api.delete_messages(chat_id, message_ids)
        message_ids = type(message_ids) == 'table' and json.encode(message_ids) or message_ids
        local success, res = api.request(config.endpoint .. api.token .. '/deleteMessages', {
            ['chat_id'] = chat_id,
            ['message_ids'] = message_ids
        })
        return success, res
    end
end
