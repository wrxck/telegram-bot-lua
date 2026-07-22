--- messages API methods.
-- @module telegram-bot-lua.methods.messages
return function(api)
    local json = require('dkjson')
    local function json_enc(v) return type(v) == 'table' and json.encode(v) or v end
    local config = require('telegram-bot-lua.config')

    --- send a text message to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param text string text of the message to be sent
    -- @param opts table optional parameters
    -- @param opts.parse_mode string mode for parsing entities (HTML, MarkdownV2); pass true for MarkdownV2
    -- @param opts.entities table list of special entities in the message text
    -- @param opts.link_preview_options table options for link preview generation
    -- @param opts.reply_markup table additional interface options (InlineKeyboardMarkup, ReplyKeyboardMarkup, etc.)
    -- @param opts.reply_parameters table description of the message to reply to
    -- @param opts.disable_notification boolean send the message silently
    -- @param opts.business_connection_id string unique identifier of the business connection
    -- @return table,number the response object and HTTP status
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
        parse_mode = api._normalize_parse_mode(parse_mode)
        local success, res = api.request(config.endpoint .. api.token .. '/sendMessage', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['entities'] = entities,
            ['link_preview_options'] = link_preview_options,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    --- send a text message as a reply to a received message.
    -- convenience wrapper around sendMessage that automatically sets reply_parameters
    -- from the given message object.
    -- @param message table the message object to reply to (must contain chat.id and message_id)
    -- @param text string text of the message to be sent
    -- @param opts table optional parameters
    -- @param opts.parse_mode string mode for parsing entities (HTML, MarkdownV2); pass true for MarkdownV2
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table override the default reply parameters
    -- @param opts.disable_notification boolean send the message silently
    -- @return table,number the response object and HTTP status
    function api.send_reply(message, text, opts)
        if type(message) ~= 'table' or not message.chat or not message.chat.id or not message.message_id then
            return false
        end
        opts = opts or {}
        -- delegate to send_message so the two parameter sets cannot drift;
        -- inject reply_parameters derived from the message unless the caller
        -- supplied their own. work on a copy so the caller's opts table is
        -- never mutated.
        local merged = {}
        for k, v in pairs(opts) do
            merged[k] = v
        end
        if not merged.reply_parameters then
            merged.reply_parameters = api.reply_parameters(message.message_id, message.chat.id, true)
        end
        return api.send_message(message.chat.id, text, merged)
    end

    --- forward a message from one chat to another.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param from_chat_id number|string unique identifier for the chat where the original message was sent
    -- @param message_id number message identifier in the chat specified in from_chat_id
    -- @param opts table optional parameters
    -- @param opts.message_thread_id number unique identifier for the target message thread (topic) of the forum
    -- @param opts.disable_notification boolean send the message silently
    -- @param opts.protect_content boolean protect the content of the forwarded message from forwarding and saving
    -- @return table,number the response object and HTTP status
    function api.forward_message(chat_id, from_chat_id, message_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/forwardMessage', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['from_chat_id'] = from_chat_id,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
            ['message_id'] = message_id
        })
        return success, res
    end

    --- forward multiple messages from one chat to another.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param from_chat_id number|string unique identifier for the chat where the original messages were sent
    -- @param message_ids table JSON-serialized list of message identifiers in the chat specified in from_chat_id
    -- @param opts table optional parameters
    -- @param opts.message_thread_id number unique identifier for the target message thread (topic) of the forum
    -- @param opts.disable_notification boolean send the messages silently
    -- @param opts.protect_content boolean protect the content of the forwarded messages from forwarding and saving
    -- @return table,number the response object and HTTP status
    function api.forward_messages(chat_id, from_chat_id, message_ids, opts)
        opts = opts or {}
        message_ids = type(message_ids) == 'table' and json.encode(message_ids) or message_ids
        local success, res = api.request(config.endpoint .. api.token .. '/forwardMessages', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['from_chat_id'] = from_chat_id,
            ['message_ids'] = message_ids,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content
        })
        return success, res
    end

    --- copy a message to another chat, without a link to the original message.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param from_chat_id number|string unique identifier for the chat where the original message was sent
    -- @param message_id number message identifier in the chat specified in from_chat_id
    -- @param opts table optional parameters
    -- @param opts.caption string new caption for the message
    -- @param opts.parse_mode string mode for parsing entities in the new caption
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @param opts.disable_notification boolean send the message silently
    -- @return table,number the response object and HTTP status
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
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['from_chat_id'] = from_chat_id,
            ['message_id'] = message_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup
        })
        return success, res
    end

    --- copy multiple messages from one chat to another, without a link to the original messages.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param from_chat_id number|string unique identifier for the chat where the original messages were sent
    -- @param message_ids table JSON-serialized list of message identifiers in the chat specified in from_chat_id
    -- @param opts table optional parameters
    -- @param opts.message_thread_id number unique identifier for the target message thread (topic) of the forum
    -- @param opts.disable_notification boolean send the messages silently
    -- @param opts.protect_content boolean protect the content of the copied messages from forwarding and saving
    -- @param opts.remove_caption boolean pass true to remove captions from the copied messages
    -- @return table,number the response object and HTTP status
    function api.copy_messages(chat_id, from_chat_id, message_ids, opts)
        opts = opts or {}
        message_ids = type(message_ids) == 'table' and json.encode(message_ids) or message_ids
        local success, res = api.request(config.endpoint .. api.token .. '/copyMessages', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['from_chat_id'] = from_chat_id,
            ['message_ids'] = message_ids,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['remove_caption'] = opts.remove_caption
        })
        return success, res
    end

    --- send a photo to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param photo string|file photo to send; pass a file_id string to send an existing file, or a file object for upload
    -- @param opts table optional parameters
    -- @param opts.caption string photo caption
    -- @param opts.parse_mode string mode for parsing entities in the caption
    -- @param opts.has_spoiler boolean pass true if the photo should be sent as a spoiler
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @param opts.disable_notification boolean send the message silently
    -- @return table,number the response object and HTTP status
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
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['has_spoiler'] = opts.has_spoiler,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
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

    --- send a live photo (a static photo paired with a short video) to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param live_photo string|file the live photo video (file_id or upload); urls are unsupported
    -- @param photo string|file the static photo (file_id or upload); urls are unsupported
    -- @param opts table optional parameters
    -- @param opts.caption string caption for the live photo
    -- @param opts.parse_mode string mode for parsing entities in the caption
    -- @param opts.has_spoiler boolean cover the live photo with a spoiler animation
    -- @param opts.show_caption_above_media boolean show the caption above the media
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @param opts.disable_notification boolean send the message silently
    -- @return table,number the response object and HTTP status
    function api.send_live_photo(chat_id, live_photo, photo, opts)
        opts = opts or {}
        local caption_entities = opts.caption_entities
        caption_entities = type(caption_entities) == 'table' and json.encode(caption_entities) or caption_entities
        local suggested_post_parameters = opts.suggested_post_parameters
        suggested_post_parameters = type(suggested_post_parameters) == 'table' and json.encode(suggested_post_parameters) or suggested_post_parameters
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendLivePhoto', {
            ['business_connection_id'] = opts.business_connection_id,
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['has_spoiler'] = opts.has_spoiler,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast,
            ['message_effect_id'] = opts.message_effect_id,
            ['suggested_post_parameters'] = suggested_post_parameters,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup
        }, {
            ['live_photo'] = live_photo,
            ['photo'] = photo
        })
        return success, res
    end

    --- send an audio file to a chat.
    -- the audio must be in .mp3 or .m4a format; the bots api sends audio files of up to 50 MB.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param audio string|file audio file to send; pass a file_id string to send an existing file, or a file object for upload
    -- @param opts table optional parameters
    -- @param opts.caption string audio caption
    -- @param opts.parse_mode string mode for parsing entities in the caption
    -- @param opts.duration number duration of the audio in seconds
    -- @param opts.performer string performer of the audio
    -- @param opts.title string track name
    -- @param opts.thumbnail string|file thumbnail of the file
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @return table,number the response object and HTTP status
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
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['duration'] = opts.duration,
            ['performer'] = opts.performer,
            ['title'] = opts.title,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
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

    --- send a general file (document) to a chat.
    -- the bots api sends files of up to 50 MB.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param document string|file file to send; pass a file_id string to send an existing file, or a file object for upload
    -- @param opts table optional parameters
    -- @param opts.caption string document caption
    -- @param opts.parse_mode string mode for parsing entities in the caption
    -- @param opts.thumbnail string|file thumbnail of the file
    -- @param opts.disable_content_type_detection boolean disables automatic server-side content type detection
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @return table,number the response object and HTTP status
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
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['disable_content_type_detection'] = opts.disable_content_type_detection,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
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

    --- send a video file to a chat.
    -- the bots api sends video files of up to 50 MB.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param video string|file video to send; pass a file_id string to send an existing file, or a file object for upload
    -- @param opts table optional parameters
    -- @param opts.duration number duration of the video in seconds
    -- @param opts.width number video width
    -- @param opts.height number video height
    -- @param opts.caption string video caption
    -- @param opts.parse_mode string mode for parsing entities in the caption
    -- @param opts.has_spoiler boolean pass true if the video should be sent as a spoiler
    -- @param opts.supports_streaming boolean pass true if the uploaded video is suitable for streaming
    -- @param opts.thumbnail string|file thumbnail of the file
    -- @param opts.reply_markup table additional interface options
    -- @return table,number the response object and HTTP status
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
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
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
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
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

    --- send an animation file (gif or h.264/mpeg-4 avc video without sound) to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param animation string|file animation to send; pass a file_id string to send an existing file, or a file object for upload
    -- @param opts table optional parameters
    -- @param opts.duration number duration of the animation in seconds
    -- @param opts.width number animation width
    -- @param opts.height number animation height
    -- @param opts.caption string animation caption
    -- @param opts.parse_mode string mode for parsing entities in the caption
    -- @param opts.has_spoiler boolean pass true if the animation should be sent as a spoiler
    -- @param opts.thumbnail string|file thumbnail of the file
    -- @param opts.reply_markup table additional interface options
    -- @return table,number the response object and HTTP status
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
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
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
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
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

    --- send a voice message to a chat.
    -- the audio must be in an .ogg file encoded with opus. the bots api sends voice files of up to 50 MB.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param voice string|file audio file to send as a voice message; pass a file_id string or a file object for upload
    -- @param opts table optional parameters
    -- @param opts.caption string voice message caption
    -- @param opts.parse_mode string mode for parsing entities in the caption
    -- @param opts.duration number duration of the voice message in seconds
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @return table,number the response object and HTTP status
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
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['duration'] = opts.duration,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
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

    --- send a video note (rounded square mp4 video message of up to 1 minute) to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param video_note string|file video note to send; pass a file_id string or a file object for upload
    -- @param opts table optional parameters
    -- @param opts.duration number duration of the video note in seconds
    -- @param opts.length number video width and height (diameter of the video message)
    -- @param opts.thumbnail string|file thumbnail of the file
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @return table,number the response object and HTTP status
    function api.send_video_note(chat_id, video_note, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendVideoNote', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['duration'] = opts.duration,
            ['length'] = opts.length,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
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

    --- send a group of photos, videos, documents or audios as an album.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param media table a JSON-serialized array of InputMediaAudio, InputMediaDocument, InputMediaPhoto and InputMediaVideo
    -- @param opts table optional parameters
    -- @param opts.message_thread_id number unique identifier for the target message thread (topic) of the forum
    -- @param opts.disable_notification boolean send the messages silently
    -- @param opts.protect_content boolean protect the content from forwarding and saving
    -- @param opts.reply_parameters table description of the message to reply to
    -- @return table,number the response object and HTTP status
    function api.send_media_group(chat_id, media, opts)
        opts = opts or {}
        media = type(media) == 'table' and json.encode(media) or media
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local success, res = api.request(config.endpoint .. api.token .. '/sendMediaGroup', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
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

    --- send a point on the map to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param latitude number latitude of the location
    -- @param longitude number longitude of the location
    -- @param opts table optional parameters
    -- @param opts.horizontal_accuracy number the radius of uncertainty for the location, in metres (0-1500)
    -- @param opts.live_period number period in seconds during which the location will be updated (60-86400)
    -- @param opts.heading number direction in which the user is moving, in degrees (1-360)
    -- @param opts.proximity_alert_radius number maximum distance in metres for proximity alerts about approaching another chat member
    -- @param opts.reply_markup table additional interface options
    -- @return table,number the response object and HTTP status
    function api.send_location(chat_id, latitude, longitude, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendLocation', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['horizontal_accuracy'] = opts.horizontal_accuracy,
            ['live_period'] = opts.live_period,
            ['heading'] = opts.heading,
            ['proximity_alert_radius'] = opts.proximity_alert_radius,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    --- send information about a venue to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param latitude number latitude of the venue
    -- @param longitude number longitude of the venue
    -- @param title string name of the venue
    -- @param address string address of the venue
    -- @param opts table optional parameters
    -- @param opts.foursquare_id string foursquare identifier of the venue
    -- @param opts.foursquare_type string foursquare type of the venue
    -- @param opts.google_place_id string google places identifier of the venue
    -- @param opts.google_place_type string google places type of the venue
    -- @param opts.reply_markup table additional interface options
    -- @return table,number the response object and HTTP status
    function api.send_venue(chat_id, latitude, longitude, title, address, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendVenue', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
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
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    --- send a phone contact to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param phone_number string contact's phone number
    -- @param first_name string contact's first name
    -- @param opts table optional parameters
    -- @param opts.last_name string contact's last name
    -- @param opts.vcard string additional data about the contact in the form of a vcard (0-2048 bytes)
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @return table,number the response object and HTTP status
    function api.send_contact(chat_id, phone_number, first_name, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendContact', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['phone_number'] = phone_number,
            ['first_name'] = first_name,
            ['last_name'] = opts.last_name,
            ['vcard'] = opts.vcard,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    --- send a native poll to a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param question string poll question (1-300 characters)
    -- @param options table a JSON-serialized list of 2-10 answer options
    -- @param opts table optional parameters
    -- @param opts.is_anonymous boolean true if the poll needs to be anonymous (defaults to true)
    -- @param opts.poll_type string poll type: "quiz" or "regular" (defaults to "regular")
    -- @param opts.allows_multiple_answers boolean true if the poll allows multiple answers (regular polls only)
    -- @param opts.correct_option_id number 0-based identifier of the correct answer option (quiz mode only)
    -- @param opts.explanation string text shown when a user chooses an incorrect answer in quiz mode
    -- @param opts.open_period number amount of time in seconds the poll will be active (5-600)
    -- @param opts.close_date number point in time (unix timestamp) when the poll will be automatically closed
    -- @param opts.reply_markup table additional interface options
    -- @return table,number the response object and HTTP status
    function api.send_poll(chat_id, question, options, opts)
        opts = opts or {}
        options = type(options) == 'table' and json.encode(options) or options
        local question_entities = opts.question_entities
        question_entities = type(question_entities) == 'table' and json.encode(question_entities) or question_entities
        local explanation_entities = opts.explanation_entities
        explanation_entities = type(explanation_entities) == 'table' and json.encode(explanation_entities) or explanation_entities
        local description_entities = opts.description_entities
        description_entities = type(description_entities) == 'table' and json.encode(description_entities) or description_entities
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local correct_option_ids = opts.correct_option_ids
        correct_option_ids = type(correct_option_ids) == 'table' and json.encode(correct_option_ids) or correct_option_ids
        local media = opts.media
        media = type(media) == 'table' and json.encode(media) or media
        local explanation_media = opts.explanation_media
        explanation_media = type(explanation_media) == 'table' and json.encode(explanation_media) or explanation_media
        local country_codes = opts.country_codes
        country_codes = type(country_codes) == 'table' and json.encode(country_codes) or country_codes
        local success, res = api.request(config.endpoint .. api.token .. '/sendPoll', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['question'] = question,
            ['question_parse_mode'] = opts.question_parse_mode,
            ['question_entities'] = question_entities,
            ['options'] = options,
            ['is_anonymous'] = opts.is_anonymous,
            ['type'] = opts.poll_type,
            ['allows_multiple_answers'] = opts.allows_multiple_answers,
            ['correct_option_id'] = opts.correct_option_id,
            ['correct_option_ids'] = correct_option_ids,
            ['explanation'] = opts.explanation,
            ['explanation_parse_mode'] = opts.explanation_parse_mode,
            ['explanation_entities'] = explanation_entities,
            ['open_period'] = opts.open_period,
            ['close_date'] = opts.close_date,
            ['is_closed'] = opts.is_closed,
            ['allows_revoting'] = opts.allows_revoting,
            ['shuffle_options'] = opts.shuffle_options,
            ['allow_adding_options'] = opts.allow_adding_options,
            ['hide_results_until_closes'] = opts.hide_results_until_closes,
            ['members_only'] = opts.members_only,
            ['country_codes'] = country_codes,
            ['media'] = media,
            ['explanation_media'] = explanation_media,
            ['description'] = opts.description,
            ['description_parse_mode'] = opts.description_parse_mode,
            ['description_entities'] = description_entities,
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

    --- send an animated emoji that will display a random value.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param opts table optional parameters
    -- @param opts.emoji string emoji on which the dice throw animation is based (default: dice)
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @param opts.disable_notification boolean send the message silently
    -- @return table,number the response object and HTTP status
    function api.send_dice(chat_id, opts)
        opts = opts or {}
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendDice', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['emoji'] = opts.emoji,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['business_connection_id'] = opts.business_connection_id,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    --- tell the user that something is happening on the bot's side.
    -- the status is set for 5 seconds or until the next message is sent.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param action string type of action to broadcast (e.g. "typing", "upload_photo", "record_video")
    -- @param opts table optional parameters
    -- @param opts.message_thread_id number unique identifier for the target message thread (topic) of the forum
    -- @param opts.business_connection_id string unique identifier of the business connection
    -- @return table,number the response object and HTTP status
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

    --- change the chosen reactions on a message.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param message_id number identifier of the target message
    -- @param opts table optional parameters
    -- @param opts.reaction table a JSON-serialized list of reaction types to set on the message
    -- @param opts.is_big boolean pass true to set the reaction with a big animation
    -- @return table,number the response object and HTTP status
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

    --- remove a specific reaction from a message.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param message_id number identifier of the target message
    -- @param opts table optional parameters
    -- @param opts.user_id number identifier of the user whose reaction will be removed
    -- @param opts.actor_chat_id number identifier of the chat whose reaction will be removed
    -- @return table,number the response object and HTTP status
    function api.delete_message_reaction(chat_id, message_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/deleteMessageReaction', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['user_id'] = opts.user_id,
            ['actor_chat_id'] = opts.actor_chat_id
        })
        return success, res
    end

    --- remove all reactions in a chat that were added by a given user or chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param opts table optional parameters
    -- @param opts.user_id number identifier of the user whose reactions will be removed
    -- @param opts.actor_chat_id number identifier of the chat whose reactions will be removed
    -- @return table,number the response object and HTTP status
    function api.delete_all_message_reactions(chat_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/deleteAllMessageReactions', {
            ['chat_id'] = chat_id,
            ['user_id'] = opts.user_id,
            ['actor_chat_id'] = opts.actor_chat_id
        })
        return success, res
    end

    --- send paid media to a channel chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param star_count number the number of telegram stars that must be paid to buy access to the media
    -- @param media table a JSON-serialized array describing the media to be sent (must include 1-10 items)
    -- @param opts table optional parameters
    -- @param opts.caption string media caption
    -- @param opts.parse_mode string mode for parsing entities in the caption
    -- @param opts.show_caption_above_media boolean pass true to show the caption above the media
    -- @param opts.reply_markup table additional interface options
    -- @param opts.reply_parameters table description of the message to reply to
    -- @param opts.payload string bot-defined paid media payload (0-128 bytes)
    -- @return table,number the response object and HTTP status
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
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['star_count'] = star_count,
            ['media'] = media,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = json_enc(opts.suggested_post_parameters),
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
        parse_mode = api._normalize_parse_mode(parse_mode)
        local rich_message = opts.rich_message
        rich_message = type(rich_message) == 'table' and json.encode(rich_message) or rich_message
        local success, res = api.request(config.endpoint .. api.token .. '/editMessageText', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = opts.inline_message_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['entities'] = entities,
            ['link_preview_options'] = link_preview_options,
            ['rich_message'] = rich_message,
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
        parse_mode = api._normalize_parse_mode(parse_mode)
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
