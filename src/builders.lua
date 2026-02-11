return function(api)
    local json = require('dkjson')

    -- Keyboard builders

    api.keyboard_meta = {}
    api.keyboard_meta.__index = api.keyboard_meta

    function api.keyboard_meta:row(row)
        table.insert(self.keyboard, row)
        return self
    end

    function api.keyboard(resize_keyboard, one_time_keyboard, selective)
        return setmetatable({
            ['keyboard'] = {},
            ['resize_keyboard'] = resize_keyboard or false,
            ['one_time_keyboard'] = one_time_keyboard or false,
            ['selective'] = selective or false
        }, api.keyboard_meta)
    end

    api.inline_keyboard_meta = {}
    api.inline_keyboard_meta.__index = api.inline_keyboard_meta

    function api.inline_keyboard_meta:row(row)
        table.insert(self.inline_keyboard, row)
        return self
    end

    function api.inline_keyboard()
        return setmetatable({
            ['inline_keyboard'] = {}
        }, api.inline_keyboard_meta)
    end

    -- Row builder

    api.row_meta = {}
    api.row_meta.__index = api.row_meta

    function api.row_meta:url_button(text, url)
        table.insert(self, {
            ['text'] = tostring(text),
            ['url'] = tostring(url)
        })
        return self
    end

    function api.row_meta:callback_data_button(text, callback_data)
        table.insert(self, {
            ['text'] = tostring(text),
            ['callback_data'] = tostring(callback_data)
        })
        return self
    end

    function api.row_meta:switch_inline_query_button(text, switch_inline_query)
        table.insert(self, {
            ['text'] = tostring(text),
            ['switch_inline_query'] = tostring(switch_inline_query)
        })
        return self
    end

    function api.row_meta:switch_inline_query_current_chat_button(text, switch_inline_query_current_chat)
        table.insert(self, {
            ['text'] = tostring(text),
            ['switch_inline_query_current_chat'] = tostring(switch_inline_query_current_chat)
        })
        return self
    end

    function api.row_meta:pay_button(text, pay)
        table.insert(self, {
            ['text'] = tostring(text),
            ['pay'] = pay
        })
        return self
    end

    function api.row(_)
        return setmetatable({}, api.row_meta)
    end

    -- Standalone button constructors

    function api.url_button(text, url, encoded)
        if not text or not url then
            return false
        end
        local button = {
            ['text'] = tostring(text),
            ['url'] = tostring(url)
        }
        if encoded then
            button = json.encode(button)
        end
        return button
    end

    function api.callback_data_button(text, callback_data, encoded)
        if not text or not callback_data then
            return false
        end
        local button = {
            ['text'] = tostring(text),
            ['callback_data'] = tostring(callback_data)
        }
        if encoded then
            button = json.encode(button)
        end
        return button
    end

    function api.switch_inline_query_button(text, switch_inline_query, encoded)
        if not text or not switch_inline_query then
            return false
        end
        local button = {
            ['text'] = tostring(text),
            ['switch_inline_query'] = tostring(switch_inline_query)
        }
        if encoded then
            button = json.encode(button)
        end
        return button
    end

    function api.switch_inline_query_current_chat_button(text, switch_inline_query_current_chat, encoded)
        if not text or not switch_inline_query_current_chat then
            return false
        end
        local button = {
            ['text'] = tostring(text),
            ['switch_inline_query_current_chat'] = tostring(switch_inline_query_current_chat)
        }
        if encoded then
            button = json.encode(button)
        end
        return button
    end

    function api.callback_game_button(text, callback_game, encoded)
        if not text or not callback_game then
            return false
        end
        local button = {
            ['text'] = tostring(text),
            ['callback_game'] = tostring(callback_game)
        }
        if encoded then
            button = json.encode(button)
        end
        return button
    end

    function api.pay_button(text, pay, encoded)
        if not text or pay == nil then
            return false
        end
        local button = {
            ['text'] = tostring(text),
            ['pay'] = pay
        }
        if encoded then
            button = json.encode(button)
        end
        return button
    end

    function api.remove_keyboard(selective)
        return {
            ['remove_keyboard'] = true,
            ['selective'] = selective or false
        }
    end

    -- Prices builder

    api.prices_meta = {}
    api.prices_meta.__index = api.prices_meta

    function api.prices_meta:labeled_price(label, amount)
        table.insert(self, {
            ['label'] = tostring(label),
            ['amount'] = tonumber(amount)
        })
        return self
    end

    function api.prices()
        return setmetatable({}, api.prices_meta)
    end

    -- Shipping options builder

    api.shipping_options_meta = {}
    api.shipping_options_meta.__index = api.shipping_options_meta

    function api.shipping_options_meta:shipping_option(id, title, prices)
        table.insert(self, {
            ['id'] = tostring(id),
            ['title'] = tostring(title),
            ['prices'] = prices
        })
        return self
    end

    function api.shipping_options()
        return setmetatable({}, api.shipping_options_meta)
    end

    -- Labeled price constructor

    function api.labeled_price(label, amount, encoded)
        if not label or not amount or tonumber(amount) == nil then
            return false
        end
        local button = {
            ['label'] = tostring(label),
            ['amount'] = tonumber(amount)
        }
        if encoded then
            button = json.encode(button)
        end
        return button
    end

    -- Mask position builder

    api.mask_position_meta = {}
    api.mask_position_meta.__index = api.mask_position_meta

    function api.mask_position_meta:position(point, x_shift, y_shift, scale)
        table.insert(self, {
            ['point'] = tostring(point),
            ['x_shift'] = tonumber(x_shift),
            ['y_shift'] = tonumber(y_shift),
            ['scale'] = tonumber(scale)
        })
        return self
    end

    function api.mask_position()
        return setmetatable({}, api.mask_position_meta)
    end

    -- Input media builders

    function api.input_media_photo(media, caption, parse_mode)
        return {
            ['type'] = 'photo',
            ['caption'] = caption,
            ['parse_mode'] = parse_mode
        }, {
            ['media'] = media
        }
    end

    function api.input_media_video(media, thumbnail, caption, parse_mode, width, height, duration, supports_streaming)
        return {
            ['type'] = 'video',
            ['caption'] = caption,
            ['parse_mode'] = parse_mode,
            ['width'] = tonumber(width),
            ['height'] = tonumber(height),
            ['duration'] = tonumber(duration),
            ['supports_streaming'] = supports_streaming
        }, {
            ['media'] = media,
            ['thumbnail'] = thumbnail
        }
    end

    function api.input_media_animation(media, thumbnail, caption, parse_mode, width, height, duration)
        return {
            ['type'] = 'animation',
            ['caption'] = caption,
            ['parse_mode'] = parse_mode,
            ['width'] = tonumber(width),
            ['height'] = tonumber(height),
            ['duration'] = tonumber(duration)
        }, {
            ['media'] = media,
            ['thumbnail'] = thumbnail
        }
    end

    function api.input_media_audio(media, thumbnail, caption, parse_mode, duration, performer, title)
        return {
            ['type'] = 'audio',
            ['caption'] = caption,
            ['parse_mode'] = parse_mode,
            ['duration'] = tonumber(duration),
            ['performer'] = performer,
            ['title'] = title
        }, {
            ['media'] = media,
            ['thumbnail'] = thumbnail
        }
    end

    function api.input_media_document(media, thumbnail, caption, parse_mode)
        return {
            ['type'] = 'document',
            ['caption'] = caption,
            ['parse_mode'] = parse_mode
        }, {
            ['media'] = media,
            ['thumbnail'] = thumbnail
        }
    end

    -- Input media meta builder (chainable)

    api.input_media_meta = {}
    api.input_media_meta.__index = api.input_media_meta

    function api.input_media_meta:photo(media, caption)
        table.insert(self, {
            ['type'] = 'photo',
            ['media'] = tostring(media),
            ['caption'] = caption
        })
        return self
    end

    function api.input_media_meta:video(media, caption, width, height, duration)
        table.insert(self, {
            ['type'] = 'video',
            ['media'] = tostring(media),
            ['caption'] = caption,
            ['width'] = width,
            ['height'] = height,
            ['duration'] = duration
        })
        return self
    end

    function api.input_media(_)
        return setmetatable({}, api.input_media_meta)
    end

    -- Input message content constructors

    function api.input_text_message_content(message_text, parse_mode, link_preview_options, encoded)
        parse_mode = (type(parse_mode) == 'boolean' and parse_mode == true) and 'markdown' or parse_mode
        local input_message_content = {
            ['message_text'] = tostring(message_text),
            ['parse_mode'] = parse_mode,
            ['link_preview_options'] = link_preview_options
        }
        input_message_content = encoded and json.encode(input_message_content) or input_message_content
        return input_message_content
    end

    function api.input_location_message_content(latitude, longitude, encoded)
        local input_message_content = {
            ['latitude'] = tonumber(latitude),
            ['longitude'] = tonumber(longitude)
        }
        input_message_content = encoded and json.encode(input_message_content) or input_message_content
        return input_message_content
    end

    function api.input_venue_message_content(latitude, longitude, title, address, foursquare_id, encoded)
        local input_message_content = {
            ['latitude'] = tonumber(latitude),
            ['longitude'] = tonumber(longitude),
            ['title'] = tostring(title),
            ['address'] = tostring(address),
            ['foursquare_id'] = foursquare_id
        }
        input_message_content = encoded and json.encode(input_message_content) or input_message_content
        return input_message_content
    end

    function api.input_contact_message_content(phone_number, first_name, last_name, encoded)
        local input_message_content = {
            ['phone_number'] = tostring(phone_number),
            ['first_name'] = tostring(first_name),
            ['last_name'] = last_name
        }
        input_message_content = encoded and json.encode(input_message_content) or input_message_content
        return input_message_content
    end

    -- Inline result builder

    api.inline_result_meta = {}
    api.inline_result_meta.__index = api.inline_result_meta

    function api.inline_result_meta:type(type)
        self['type'] = tostring(type)
        return self
    end

    function api.inline_result_meta:id(id)
        self['id'] = id and tostring(id) or '1'
        return self
    end

    function api.inline_result_meta:title(title)
        self['title'] = tostring(title)
        return self
    end

    function api.inline_result_meta:input_message_content(input_message_content)
        self['input_message_content'] = input_message_content
        return self
    end

    function api.inline_result_meta:reply_markup(reply_markup)
        self['reply_markup'] = reply_markup
        return self
    end

    function api.inline_result_meta:url(url)
        self['url'] = tostring(url)
        return self
    end

    function api.inline_result_meta:hide_url(hide_url)
        self['hide_url'] = hide_url or false
        return self
    end

    function api.inline_result_meta:description(description)
        self['description'] = tostring(description)
        return self
    end

    function api.inline_result_meta:thumbnail_url(thumbnail_url)
        self['thumbnail_url'] = tostring(thumbnail_url)
        return self
    end

    function api.inline_result_meta:thumbnail_width(thumbnail_width)
        self['thumbnail_width'] = tonumber(thumbnail_width)
        return self
    end

    function api.inline_result_meta:thumbnail_height(thumbnail_height)
        self['thumbnail_height'] = tonumber(thumbnail_height)
        return self
    end

    function api.inline_result_meta:photo_url(photo_url)
        self['photo_url'] = tostring(photo_url)
        return self
    end

    function api.inline_result_meta:photo_width(photo_width)
        self['photo_width'] = tonumber(photo_width)
        return self
    end

    function api.inline_result_meta:photo_height(photo_height)
        self['photo_height'] = tonumber(photo_height)
        return self
    end

    function api.inline_result_meta:caption(caption)
        self['caption'] = tostring(caption)
        return self
    end

    function api.inline_result_meta:gif_url(gif_url)
        self['gif_url'] = tostring(gif_url)
        return self
    end

    function api.inline_result_meta:gif_width(gif_width)
        self['gif_width'] = tonumber(gif_width)
        return self
    end

    function api.inline_result_meta:gif_height(gif_height)
        self['gif_height'] = tonumber(gif_height)
        return self
    end

    function api.inline_result_meta:mpeg4_url(mpeg4_url)
        self['mpeg4_url'] = tostring(mpeg4_url)
        return self
    end

    function api.inline_result_meta:mpeg4_width(mpeg4_width)
        self['mpeg4_width'] = tonumber(mpeg4_width)
        return self
    end

    function api.inline_result_meta:mpeg4_height(mpeg4_height)
        self['mpeg4_height'] = tonumber(mpeg4_height)
        return self
    end

    function api.inline_result_meta:video_url(video_url)
        self['video_url'] = tostring(video_url)
        return self
    end

    function api.inline_result_meta:mime_type(mime_type)
        self['mime_type'] = tostring(mime_type)
        return self
    end

    function api.inline_result_meta:video_width(video_width)
        self['video_width'] = tonumber(video_width)
        return self
    end

    function api.inline_result_meta:video_height(video_height)
        self['video_height'] = tonumber(video_height)
        return self
    end

    function api.inline_result_meta:video_duration(video_duration)
        self['video_duration'] = tonumber(video_duration)
        return self
    end

    function api.inline_result_meta:audio_url(audio_url)
        self['audio_url'] = tostring(audio_url)
        return self
    end

    function api.inline_result_meta:performer(performer)
        self['performer'] = tostring(performer)
        return self
    end

    function api.inline_result_meta:audio_duration(audio_duration)
        self['audio_duration'] = tonumber(audio_duration)
        return self
    end

    function api.inline_result_meta:voice_url(voice_url)
        self['voice_url'] = tostring(voice_url)
        return self
    end

    function api.inline_result_meta:voice_duration(voice_duration)
        self['voice_duration'] = tonumber(voice_duration)
        return self
    end

    function api.inline_result_meta:document_url(document_url)
        self['document_url'] = tostring(document_url)
        return self
    end

    function api.inline_result_meta:latitude(latitude)
        self['latitude'] = tonumber(latitude)
        return self
    end

    function api.inline_result_meta:longitude(longitude)
        self['longitude'] = tonumber(longitude)
        return self
    end

    function api.inline_result_meta:live_period(live_period)
        self['live_period'] = tonumber(live_period)
        return self
    end

    function api.inline_result_meta:address(address)
        self['address'] = tostring(address)
        return self
    end

    function api.inline_result_meta:foursquare_id(foursquare_id)
        self['foursquare_id'] = tostring(foursquare_id)
        return self
    end

    function api.inline_result_meta:phone_number(phone_number)
        self['phone_number'] = tostring(phone_number)
        return self
    end

    function api.inline_result_meta:first_name(first_name)
        self['first_name'] = tostring(first_name)
        return self
    end

    function api.inline_result_meta:last_name(last_name)
        self['last_name'] = tostring(last_name)
        return self
    end

    function api.inline_result_meta:game_short_name(game_short_name)
        self['game_short_name'] = tostring(game_short_name)
        return self
    end

    function api.inline_result()
        return setmetatable({}, api.inline_result_meta)
    end

    -- Chat permissions constructor

    function api.chat_permissions(opts)
        opts = opts or {}
        return {
            ['can_send_messages'] = opts.can_send_messages,
            ['can_send_audios'] = opts.can_send_audios,
            ['can_send_documents'] = opts.can_send_documents,
            ['can_send_photos'] = opts.can_send_photos,
            ['can_send_videos'] = opts.can_send_videos,
            ['can_send_video_notes'] = opts.can_send_video_notes,
            ['can_send_voice_notes'] = opts.can_send_voice_notes,
            ['can_send_polls'] = opts.can_send_polls,
            ['can_send_other_messages'] = opts.can_send_other_messages,
            ['can_add_web_page_previews'] = opts.can_add_web_page_previews,
            ['can_change_info'] = opts.can_change_info,
            ['can_invite_users'] = opts.can_invite_users,
            ['can_pin_messages'] = opts.can_pin_messages,
            ['can_manage_topics'] = opts.can_manage_topics
        }
    end

    -- Chat administrator rights constructor

    function api.chat_administrator_rights(opts)
        opts = opts or {}
        return {
            ['is_anonymous'] = opts.is_anonymous,
            ['can_manage_chat'] = opts.can_manage_chat,
            ['can_delete_messages'] = opts.can_delete_messages,
            ['can_manage_video_chats'] = opts.can_manage_video_chats,
            ['can_restrict_members'] = opts.can_restrict_members,
            ['can_promote_members'] = opts.can_promote_members,
            ['can_change_info'] = opts.can_change_info,
            ['can_invite_users'] = opts.can_invite_users,
            ['can_post_messages'] = opts.can_post_messages,
            ['can_edit_messages'] = opts.can_edit_messages,
            ['can_pin_messages'] = opts.can_pin_messages,
            ['can_post_stories'] = opts.can_post_stories,
            ['can_edit_stories'] = opts.can_edit_stories,
            ['can_delete_stories'] = opts.can_delete_stories,
            ['can_manage_topics'] = opts.can_manage_topics,
            ['can_manage_direct_messages'] = opts.can_manage_direct_messages
        }
    end

    -- Bot command constructors

    function api.bot_command(command, description)
        command = tostring(command)
        description = tostring(description)
        if command:len() > 32 then
            command = command:sub(1, 32)
        end
        if description:len() > 256 then
            description = description:sub(1, 256)
        end
        return {
            ['command'] = command,
            ['description'] = description
        }
    end

    function api.bot_command_scope_default()
        return { ['type'] = 'default' }
    end

    function api.bot_command_scope_all_private_chats()
        return { ['type'] = 'all_private_chats' }
    end

    function api.bot_command_scope_all_group_chats()
        return { ['type'] = 'all_group_chats' }
    end

    function api.bot_command_scope_all_chat_administrators()
        return { ['type'] = 'all_chat_administrators' }
    end

    function api.bot_command_scope_chat(chat_id)
        return { ['type'] = 'chat', ['chat_id'] = chat_id }
    end

    function api.bot_command_scope_chat_administrators(chat_id)
        return { ['type'] = 'chat_administrators', ['chat_id'] = chat_id }
    end

    function api.bot_command_scope_chat_member(chat_id, user_id)
        return { ['type'] = 'chat_member', ['chat_id'] = chat_id, ['user_id'] = user_id }
    end

    -- Menu button constructors

    function api.menu_button_commands()
        return { ['type'] = 'commands' }
    end

    function api.menu_button_web_app(text, web_app)
        return { ['type'] = 'web_app', ['text'] = text, ['web_app'] = web_app }
    end

    function api.menu_button_default()
        return { ['type'] = 'default' }
    end

    -- Link preview options

    function api.link_preview_options(is_disabled, url, prefer_small_media, prefer_large_media, show_above_text)
        return {
            ['is_disabled'] = is_disabled,
            ['url'] = url,
            ['prefer_small_media'] = prefer_small_media,
            ['prefer_large_media'] = prefer_large_media,
            ['show_above_text'] = show_above_text
        }
    end

    -- Message entity

    function api.message_entity(entity_type, offset, length, url, user, language, custom_emoji_id)
        return {
            ['type'] = tostring(entity_type),
            ['offset'] = tonumber(offset),
            ['length'] = tonumber(length),
            ['url'] = tostring(url),
            ['user'] = type(user) == 'table' and user or nil,
            ['language'] = tostring(language),
            ['custom_emoji_id'] = tostring(custom_emoji_id)
        }
    end

    -- Reply parameters

    function api.reply_parameters(message_id, chat_id, allow_sending_without_reply, quote, quote_parse_mode, quote_entities, quote_position)
        quote_entities = type(quote_entities) == 'table' and json.encode(quote_entities) or quote_entities
        return {
            ['message_id'] = tonumber(message_id),
            ['chat_id'] = chat_id,
            ['allow_sending_without_reply'] = allow_sending_without_reply,
            ['quote'] = quote,
            ['quote_parse_mode'] = quote_parse_mode,
            ['quote_entities'] = quote_entities,
            ['quote_position'] = tonumber(quote_position)
        }
    end

    -- Input sticker

    function api.input_sticker(sticker, emoji_list, mask_position, keywords)
        return {
            ['sticker'] = sticker,
            ['emoji_list'] = emoji_list,
            ['mask_position'] = mask_position,
            ['keywords'] = keywords
        }
    end

    -- Inline query results button

    function api.inline_query_results_button(text, web_app, start_parameter)
        return {
            ['text'] = text,
            ['web_app'] = web_app,
            ['start_parameter'] = start_parameter
        }
    end

    -- Reaction type constructors

    function api.reaction_type_emoji(emoji)
        return { ['type'] = 'emoji', ['emoji'] = emoji }
    end

    function api.reaction_type_custom_emoji(custom_emoji_id)
        return { ['type'] = 'custom_emoji', ['custom_emoji_id'] = custom_emoji_id }
    end

    -- Web app info

    function api.web_app_info(url)
        return { ['url'] = url }
    end

    -- Accepted gift types

    function api.accepted_gift_types(opts)
        opts = opts or {}
        return {
            ['regular_gifts'] = opts.regular_gifts,
            ['upgraded_gifts'] = opts.upgraded_gifts,
            ['premium_subscription'] = opts.premium_subscription
        }
    end

    -- Suggested post parameters

    function api.suggested_post_parameters(opts)
        opts = opts or {}
        return {
            ['star_count'] = opts.star_count,
            ['pay_for_sponsored_message'] = opts.pay_for_sponsored_message
        }
    end

    -- Passport element error constructors

    function api.passport_element_error_data_field(error_type, field_name, data_hash, message)
        return {
            ['source'] = 'data',
            ['type'] = error_type,
            ['field_name'] = field_name,
            ['data_hash'] = data_hash,
            ['message'] = message
        }
    end

    function api.passport_element_error_front_side(error_type, file_hash, message)
        return {
            ['source'] = 'front_side',
            ['type'] = error_type,
            ['file_hash'] = file_hash,
            ['message'] = message
        }
    end

    function api.passport_element_error_reverse_side(error_type, file_hash, message)
        return {
            ['source'] = 'reverse_side',
            ['type'] = error_type,
            ['file_hash'] = file_hash,
            ['message'] = message
        }
    end

    function api.passport_element_error_selfie(error_type, file_hash, message)
        return {
            ['source'] = 'selfie',
            ['type'] = error_type,
            ['file_hash'] = file_hash,
            ['message'] = message
        }
    end

    function api.passport_element_error_file(error_type, file_hash, message)
        return {
            ['source'] = 'file',
            ['type'] = error_type,
            ['file_hash'] = file_hash,
            ['message'] = message
        }
    end

    function api.passport_element_error_files(error_type, file_hashes, message)
        return {
            ['source'] = 'files',
            ['type'] = error_type,
            ['file_hashes'] = file_hashes,
            ['message'] = message
        }
    end

    function api.passport_element_error_translation_file(error_type, file_hash, message)
        return {
            ['source'] = 'translation_file',
            ['type'] = error_type,
            ['file_hash'] = file_hash,
            ['message'] = message
        }
    end

    function api.passport_element_error_translation_files(error_type, file_hashes, message)
        return {
            ['source'] = 'translation_files',
            ['type'] = error_type,
            ['file_hashes'] = file_hashes,
            ['message'] = message
        }
    end

    function api.passport_element_error_unspecified(error_type, element_hash, message)
        return {
            ['source'] = 'unspecified',
            ['type'] = error_type,
            ['element_hash'] = element_hash,
            ['message'] = message
        }
    end
end
