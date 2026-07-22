--- keyboard and inline markup builders.
-- @module telegram-bot-lua.builders
return function(api)
    local json = require('dkjson')

    -- mark a table as a JSON object so dkjson encodes it as {} even when all
    -- its fields are optional and absent (a bare empty lua table would
    -- otherwise serialize as [], which telegram rejects for object types).
    local function json_object(t)
        return setmetatable(t, { ['__jsontype'] = 'object' })
    end

    -- keyboard builders

    api.keyboard_meta = {}
    api.keyboard_meta.__index = api.keyboard_meta

    --- add a row of buttons to the reply keyboard.
    -- @param row table a row of keyboard button objects
    -- @return table self for chaining
    function api.keyboard_meta:row(row)
        table.insert(self.keyboard, row)
        return self
    end

    --- create a reply keyboard markup with a chainable builder pattern.
    -- @param resize_keyboard boolean optional request to resize the keyboard vertically
    -- @param one_time_keyboard boolean optional request to hide the keyboard after use
    -- @param selective boolean optional show keyboard to specific users only
    -- @return table a reply keyboard markup object with metatable for chaining
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

    --- add a row of buttons to the inline keyboard.
    -- @param row table a row of inline keyboard button objects
    -- @return table self for chaining
    function api.inline_keyboard_meta:row(row)
        table.insert(self.inline_keyboard, row)
        return self
    end

    --- create an inline keyboard markup with a chainable builder pattern.
    -- @return table an inline keyboard markup object with metatable for chaining
    function api.inline_keyboard()
        return setmetatable({
            ['inline_keyboard'] = {}
        }, api.inline_keyboard_meta)
    end

    -- Row builder

    api.row_meta = {}
    api.row_meta.__index = api.row_meta

    --- add a url button to the row.
    -- @param text string label text for the button
    -- @param url string http or tg:// url to open when the button is pressed
    -- @return table self for chaining
    function api.row_meta:url_button(text, url)
        table.insert(self, {
            ['text'] = tostring(text),
            ['url'] = tostring(url)
        })
        return self
    end

    --- add a callback data button to the row.
    -- @param text string label text for the button
    -- @param callback_data string data to be sent in a callback query when the button is pressed
    -- @return table self for chaining
    function api.row_meta:callback_data_button(text, callback_data)
        table.insert(self, {
            ['text'] = tostring(text),
            ['callback_data'] = tostring(callback_data)
        })
        return self
    end

    --- add a switch inline query button to the row.
    -- @param text string label text for the button
    -- @param switch_inline_query string query to insert into the chat input when switching to inline mode
    -- @return table self for chaining
    function api.row_meta:switch_inline_query_button(text, switch_inline_query)
        table.insert(self, {
            ['text'] = tostring(text),
            ['switch_inline_query'] = tostring(switch_inline_query)
        })
        return self
    end

    --- add a switch inline query current chat button to the row.
    -- @param text string label text for the button
    -- @param switch_inline_query_current_chat string query to insert into the current chat input for inline mode
    -- @return table self for chaining
    function api.row_meta:switch_inline_query_current_chat_button(text, switch_inline_query_current_chat)
        table.insert(self, {
            ['text'] = tostring(text),
            ['switch_inline_query_current_chat'] = tostring(switch_inline_query_current_chat)
        })
        return self
    end

    --- add a pay button to the row.
    -- @param text string label text for the button
    -- @param pay boolean whether this is a pay button
    -- @return table self for chaining
    function api.row_meta:pay_button(text, pay)
        table.insert(self, {
            ['text'] = tostring(text),
            ['pay'] = pay
        })
        return self
    end

    --- create a row of inline keyboard buttons with a chainable builder pattern.
    -- @return table a row object with metatable for chaining button additions
    function api.row()
        return setmetatable({}, api.row_meta)
    end

    -- Standalone button constructors

    --- create a standalone url inline keyboard button.
    -- @param text string label text for the button
    -- @param url string http or tg:// url to open when the button is pressed
    -- @param encoded boolean optional json-encode the result
    -- @return table|string|boolean the button object, json string if encoded, or false on missing params
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

    --- create a standalone callback data inline keyboard button.
    -- @param text string label text for the button
    -- @param callback_data string data to be sent in a callback query when pressed
    -- @param encoded boolean optional json-encode the result
    -- @return table|string|boolean the button object, json string if encoded, or false on missing params
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

    --- create a standalone switch inline query button.
    -- @param text string label text for the button
    -- @param switch_inline_query string query to insert when switching to inline mode in another chat
    -- @param encoded boolean optional json-encode the result
    -- @return table|string|boolean the button object, json string if encoded, or false on missing params
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

    --- create a standalone switch inline query current chat button.
    -- @param text string label text for the button
    -- @param switch_inline_query_current_chat string query to insert into the current chat for inline mode
    -- @param encoded boolean optional json-encode the result
    -- @return table|string|boolean the button object, json string if encoded, or false on missing params
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

    --- create a standalone callback game inline keyboard button.
    -- @param text string label text for the button
    -- @param callback_game string description of the game to be launched
    -- @param encoded boolean optional json-encode the result
    -- @return table|string|boolean the button object, json string if encoded, or false on missing params
    function api.callback_game_button(text, callback_game, encoded)
        if not text or not callback_game then
            return false
        end
        -- a CallbackGame table must be passed through intact; only scalars
        -- are stringified. CallbackGame is an empty placeholder object, so an
        -- empty table gets the object hint to avoid encoding as [].
        local game = callback_game
        if type(game) == 'table' then
            if next(game) == nil and getmetatable(game) == nil then
                game = json_object({})
            end
        else
            game = tostring(game)
        end
        local button = {
            ['text'] = tostring(text),
            ['callback_game'] = game
        }
        if encoded then
            button = json.encode(button)
        end
        return button
    end

    --- create a standalone pay inline keyboard button.
    -- @param text string label text for the button
    -- @param pay boolean whether this is a pay button
    -- @param encoded boolean optional json-encode the result
    -- @return table|string|boolean the button object, json string if encoded, or false on missing params
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

    --- create a keyboard button that requests users when pressed.
    -- @param text string label text for the button
    -- @param request_id number signed 32-bit identifier of the request, unique within the message
    -- @param opts table optional user_is_bot, user_is_premium, max_quantity, request_name, request_username, request_photo
    -- @return table a keyboard button object with a request_users field
    function api.keyboard_button_request_users(text, request_id, opts)
        opts = opts or {}
        return {
            ['text'] = text,
            ['request_users'] = {
                ['request_id'] = tonumber(request_id),
                ['user_is_bot'] = opts.user_is_bot,
                ['user_is_premium'] = opts.user_is_premium,
                ['max_quantity'] = tonumber(opts.max_quantity),
                ['request_name'] = opts.request_name,
                ['request_username'] = opts.request_username,
                ['request_photo'] = opts.request_photo
            }
        }
    end

    --- create a keyboard button that requests a chat when pressed.
    -- @param text string label text for the button
    -- @param request_id number signed 32-bit identifier of the request, unique within the message
    -- @param chat_is_channel boolean pass true to request a channel chat, false to request a group or supergroup
    -- @param opts table optional chat_is_forum, chat_has_username, chat_is_created, user_administrator_rights, bot_administrator_rights, bot_is_member, request_title, request_username, request_photo
    -- @return table a keyboard button object with a request_chat field
    function api.keyboard_button_request_chat(text, request_id, chat_is_channel, opts)
        opts = opts or {}
        return {
            ['text'] = text,
            ['request_chat'] = {
                ['request_id'] = tonumber(request_id),
                ['chat_is_channel'] = chat_is_channel,
                ['chat_is_forum'] = opts.chat_is_forum,
                ['chat_has_username'] = opts.chat_has_username,
                ['chat_is_created'] = opts.chat_is_created,
                ['user_administrator_rights'] = opts.user_administrator_rights,
                ['bot_administrator_rights'] = opts.bot_administrator_rights,
                ['bot_is_member'] = opts.bot_is_member,
                ['request_title'] = opts.request_title,
                ['request_username'] = opts.request_username,
                ['request_photo'] = opts.request_photo
            }
        }
    end

    --- create a keyboard button that requests the user's contact when pressed.
    -- @param text string label text for the button
    -- @return table a keyboard button object with request_contact set to true
    function api.keyboard_button_request_contact(text)
        return {
            ['text'] = text,
            ['request_contact'] = true
        }
    end

    --- create a keyboard button that requests the user's location when pressed.
    -- @param text string label text for the button
    -- @return table a keyboard button object with request_location set to true
    function api.keyboard_button_request_location(text)
        return {
            ['text'] = text,
            ['request_location'] = true
        }
    end

    --- create a keyboard button that asks the user to create a poll when pressed.
    -- @param text string label text for the button
    -- @param poll_type string optional "quiz", "regular", or nil for any type
    -- @return table a keyboard button object with a request_poll field
    function api.keyboard_button_request_poll(text, poll_type)
        return {
            ['text'] = text,
            ['request_poll'] = json_object({
                ['type'] = poll_type
            })
        }
    end

    --- create a keyboard button that launches a web app when pressed.
    -- @param text string label text for the button
    -- @param url string an https url of a web app to be opened
    -- @return table a keyboard button object with a web_app field
    function api.keyboard_button_web_app(text, url)
        return {
            ['text'] = text,
            ['web_app'] = {
                ['url'] = url
            }
        }
    end

    --- create a login url object for an inline keyboard button.
    -- @param url string an https url to be opened with user authorization data
    -- @param opts table optional forward_text, bot_username, request_write_access
    -- @return table a login url object
    function api.login_url(url, opts)
        opts = opts or {}
        return {
            ['url'] = url,
            ['forward_text'] = opts.forward_text,
            ['bot_username'] = opts.bot_username,
            ['request_write_access'] = opts.request_write_access
        }
    end

    --- create a copy text button for an inline keyboard.
    -- @param text string label text for the button
    -- @param copy_text string the text to be copied to the clipboard; 1-256 characters
    -- @return table an inline keyboard button object with a copy_text field
    function api.copy_text_button(text, copy_text)
        return {
            ['text'] = text,
            ['copy_text'] = {
                ['text'] = copy_text
            }
        }
    end

    --- create a remove keyboard markup to request removal of the custom keyboard.
    -- @param selective boolean optional remove keyboard for specific users only
    -- @return table a ReplyKeyboardRemove object
    function api.remove_keyboard(selective)
        return {
            ['remove_keyboard'] = true,
            ['selective'] = selective or false
        }
    end

    -- Prices builder

    api.prices_meta = {}
    api.prices_meta.__index = api.prices_meta

    --- add a labelled price to the prices array.
    -- @param label string price label, e.g. "product price"
    -- @param amount number price in the smallest units of the currency
    -- @return table self for chaining
    function api.prices_meta:labeled_price(label, amount)
        table.insert(self, {
            ['label'] = tostring(label),
            ['amount'] = tonumber(amount)
        })
        return self
    end

    --- create a prices array with a chainable builder pattern for payment invoices.
    -- @return table a prices array object with metatable for chaining
    function api.prices()
        return setmetatable({}, api.prices_meta)
    end

    -- Shipping options builder

    api.shipping_options_meta = {}
    api.shipping_options_meta.__index = api.shipping_options_meta

    --- add a shipping option to the shipping options array.
    -- @param id string unique identifier for the shipping option
    -- @param title string display name for the shipping option
    -- @param prices table array of labelled price objects for this option
    -- @return table self for chaining
    function api.shipping_options_meta:shipping_option(id, title, prices)
        table.insert(self, {
            ['id'] = tostring(id),
            ['title'] = tostring(title),
            ['prices'] = prices
        })
        return self
    end

    --- create a shipping options array with a chainable builder pattern.
    -- @return table a shipping options array object with metatable for chaining
    function api.shipping_options()
        return setmetatable({}, api.shipping_options_meta)
    end

    -- Labeled price constructor

    --- create a standalone labelled price object for payment invoices.
    -- @param label string price label, e.g. "product price"
    -- @param amount number price in the smallest units of the currency
    -- @param encoded boolean optional json-encode the result
    -- @return table|string|boolean the labelled price object, json string if encoded, or false on invalid params
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

    --- add a mask position entry specifying where a mask should be placed on a face.
    -- @param point string the part of the face to place the mask on ("forehead", "eyes", "mouth", or "chin")
    -- @param x_shift number shift by x-axis measured in widths of the mask
    -- @param y_shift number shift by y-axis measured in heights of the mask
    -- @param scale number mask scaling coefficient
    -- @return table self for chaining
    function api.mask_position_meta:position(point, x_shift, y_shift, scale)
        table.insert(self, {
            ['point'] = tostring(point),
            ['x_shift'] = tonumber(x_shift),
            ['y_shift'] = tonumber(y_shift),
            ['scale'] = tonumber(scale)
        })
        return self
    end

    --- create a mask position array with a chainable builder pattern.
    -- @return table a mask position array object with metatable for chaining
    function api.mask_position()
        return setmetatable({}, api.mask_position_meta)
    end

    -- Input media builders

    --- create an input media photo object for use with sendMediaGroup and editMessageMedia.
    -- @param media string file_id, url, or file path for the photo
    -- @param caption string optional caption for the photo
    -- @param parse_mode string optional parse mode for the caption ("MarkdownV2", "HTML", etc.)
    -- @return table,table the input media object and a table of file references
    function api.input_media_photo(media, caption, parse_mode)
        return {
            ['type'] = 'photo',
            ['caption'] = caption,
            ['parse_mode'] = parse_mode
        }, {
            ['media'] = media
        }
    end

    --- create an input media video object for use with sendMediaGroup and editMessageMedia.
    -- @param media string file_id, url, or file path for the video
    -- @param thumbnail string optional thumbnail file_id or file path
    -- @param caption string optional caption for the video
    -- @param parse_mode string optional parse mode for the caption
    -- @param width number optional video width
    -- @param height number optional video height
    -- @param duration number optional video duration in seconds
    -- @param supports_streaming boolean optional whether the video is suitable for streaming
    -- @return table,table the input media object and a table of file references
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

    --- create an input media sticker object (Bot API 10.0).
    -- @param media string file_id, url, or attach reference for the sticker
    -- @param emoji string optional emoji associated with a just-uploaded sticker
    -- @return table,table the input media object and a table of file references
    function api.input_media_sticker(media, emoji)
        return {
            ['type'] = 'sticker',
            ['emoji'] = emoji
        }, {
            ['media'] = media
        }
    end

    --- create an input media location object (Bot API 10.0).
    -- @param latitude number latitude of the location
    -- @param longitude number longitude of the location
    -- @param horizontal_accuracy number optional radius of uncertainty in metres (0-1500)
    -- @return table the input media object
    function api.input_media_location(latitude, longitude, horizontal_accuracy)
        return {
            ['type'] = 'location',
            ['latitude'] = tonumber(latitude),
            ['longitude'] = tonumber(longitude),
            ['horizontal_accuracy'] = tonumber(horizontal_accuracy)
        }
    end

    --- create an input media venue object (Bot API 10.0).
    -- @param latitude number latitude of the venue
    -- @param longitude number longitude of the venue
    -- @param title string name of the venue
    -- @param address string address of the venue
    -- @param opts table optional foursquare_id, foursquare_type, google_place_id, google_place_type
    -- @return table the input media object
    function api.input_media_venue(latitude, longitude, title, address, opts)
        opts = opts or {}
        return {
            ['type'] = 'venue',
            ['latitude'] = tonumber(latitude),
            ['longitude'] = tonumber(longitude),
            ['title'] = title,
            ['address'] = address,
            ['foursquare_id'] = opts.foursquare_id,
            ['foursquare_type'] = opts.foursquare_type,
            ['google_place_id'] = opts.google_place_id,
            ['google_place_type'] = opts.google_place_type
        }
    end

    --- create an input media live photo object (Bot API 10.0).
    -- @param media string file_id or attach reference for the live photo video
    -- @param photo string file_id or attach reference for the static photo
    -- @param opts table optional caption, parse_mode, caption_entities, show_caption_above_media, has_spoiler
    -- @return table,table the input media object and a table of file references
    function api.input_media_live_photo(media, photo, opts)
        opts = opts or {}
        return {
            ['type'] = 'live_photo',
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = opts.caption_entities,
            ['show_caption_above_media'] = opts.show_caption_above_media,
            ['has_spoiler'] = opts.has_spoiler
        }, {
            ['media'] = media,
            ['photo'] = photo
        }
    end

    --- create an input media link object (Bot API 10.1).
    -- @param url string HTTP url of the link
    -- @return table the input media object
    function api.input_media_link(url)
        return {
            ['type'] = 'link',
            ['url'] = url
        }
    end

    --- create an input paid media live photo object (Bot API 10.0).
    -- @param media string file_id or attach reference for the live photo video
    -- @param photo string file_id or attach reference for the static photo
    -- @return table,table the input paid media object and a table of file references
    function api.input_paid_media_live_photo(media, photo)
        return {
            ['type'] = 'live_photo'
        }, {
            ['media'] = media,
            ['photo'] = photo
        }
    end

    --- create an input paid media photo object.
    -- @param media string file_id, url, or attach reference for the photo
    -- @return table the input paid media object
    function api.input_paid_media_photo(media)
        return {
            ['type'] = 'photo',
            ['media'] = media
        }
    end

    --- create an input paid media video object.
    -- @param media string file_id, url, or attach reference for the video
    -- @param opts table optional thumbnail, cover, start_timestamp, width, height, duration, supports_streaming
    -- @return table the input paid media object
    function api.input_paid_media_video(media, opts)
        opts = opts or {}
        return {
            ['type'] = 'video',
            ['media'] = media,
            ['thumbnail'] = opts.thumbnail,
            ['cover'] = opts.cover,
            ['start_timestamp'] = tonumber(opts.start_timestamp),
            ['width'] = tonumber(opts.width),
            ['height'] = tonumber(opts.height),
            ['duration'] = tonumber(opts.duration),
            ['supports_streaming'] = opts.supports_streaming
        }
    end

    --- create an input poll option object.
    -- @param text string option text, 1-100 characters
    -- @param opts table optional text_parse_mode, text_entities, media
    -- @return table the input poll option object
    function api.input_poll_option(text, opts)
        opts = opts or {}
        return {
            ['text'] = text,
            ['text_parse_mode'] = opts.text_parse_mode,
            ['text_entities'] = opts.text_entities,
            ['media'] = opts.media
        }
    end

    --- create an input checklist task object.
    -- @param id number unique positive identifier of the task
    -- @param text string text of the task, 1-100 characters
    -- @param opts table optional parse_mode, text_entities
    -- @return table the input checklist task object
    function api.input_checklist_task(id, text, opts)
        opts = opts or {}
        return {
            ['id'] = tonumber(id),
            ['text'] = text,
            ['parse_mode'] = opts.parse_mode,
            ['text_entities'] = opts.text_entities
        }
    end

    --- create an input checklist object.
    -- @param title string title of the checklist, 1-255 characters
    -- @param tasks table array of input checklist task objects, 1-30 tasks
    -- @param opts table optional parse_mode, title_entities, others_can_add_tasks, others_can_mark_tasks_as_done
    -- @return table the input checklist object
    function api.input_checklist(title, tasks, opts)
        opts = opts or {}
        return {
            ['title'] = title,
            ['parse_mode'] = opts.parse_mode,
            ['title_entities'] = opts.title_entities,
            ['tasks'] = tasks,
            ['others_can_add_tasks'] = opts.others_can_add_tasks,
            ['others_can_mark_tasks_as_done'] = opts.others_can_mark_tasks_as_done
        }
    end

    --- create an input story content photo object.
    -- @param photo string the photo to post as a story; file_id, url, or attach reference
    -- @return table the input story content object
    function api.input_story_content_photo(photo)
        return {
            ['type'] = 'photo',
            ['photo'] = photo
        }
    end

    --- create an input story content video object.
    -- @param video string the video to post as a story; file_id, url, or attach reference
    -- @param opts table optional duration, cover_frame_timestamp, is_animation
    -- @return table the input story content object
    function api.input_story_content_video(video, opts)
        opts = opts or {}
        return {
            ['type'] = 'video',
            ['video'] = video,
            ['duration'] = tonumber(opts.duration),
            ['cover_frame_timestamp'] = tonumber(opts.cover_frame_timestamp),
            ['is_animation'] = opts.is_animation
        }
    end

    --- create an input profile photo static object.
    -- @param photo string the static profile photo; file_id, url, or attach reference
    -- @return table the input profile photo object
    function api.input_profile_photo_static(photo)
        return {
            ['type'] = 'static',
            ['photo'] = photo
        }
    end

    --- create an input profile photo animated object.
    -- @param animation string the animated profile photo; file_id, url, or attach reference
    -- @param opts table optional main_frame_timestamp
    -- @return table the input profile photo object
    function api.input_profile_photo_animated(animation, opts)
        opts = opts or {}
        return {
            ['type'] = 'animated',
            ['animation'] = animation,
            ['main_frame_timestamp'] = tonumber(opts.main_frame_timestamp)
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
        -- coerce dimensions like the standalone input_media_video builder.
        table.insert(self, {
            ['type'] = 'video',
            ['media'] = tostring(media),
            ['caption'] = caption,
            ['width'] = tonumber(width),
            ['height'] = tonumber(height),
            ['duration'] = tonumber(duration)
        })
        return self
    end

    function api.input_media()
        return setmetatable({}, api.input_media_meta)
    end

    -- Input message content constructors

    function api.input_text_message_content(message_text, parse_mode, link_preview_options, encoded)
        parse_mode = api._normalize_parse_mode(parse_mode)
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
        return json_object({
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
            ['can_manage_topics'] = opts.can_manage_topics,
            ['can_edit_tag'] = opts.can_edit_tag
        })
    end

    -- Chat administrator rights constructor

    function api.chat_administrator_rights(opts)
        opts = opts or {}
        return json_object({
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
            ['can_manage_direct_messages'] = opts.can_manage_direct_messages,
            ['can_manage_tags'] = opts.can_manage_tags
        })
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
        -- optional fields must stay nil when absent; unconditional tostring
        -- would send the literal string "nil" to telegram.
        return {
            ['type'] = tostring(entity_type),
            ['offset'] = tonumber(offset),
            ['length'] = tonumber(length),
            ['url'] = url ~= nil and tostring(url) or nil,
            ['user'] = type(user) == 'table' and user or nil,
            ['language'] = language ~= nil and tostring(language) or nil,
            ['custom_emoji_id'] = custom_emoji_id ~= nil and tostring(custom_emoji_id) or nil
        }
    end

    -- Reply parameters

    function api.reply_parameters(message_id, chat_id, allow_sending_without_reply, quote, quote_parse_mode, quote_entities, quote_position, opts)
        -- quote_entities stays a table: consumers json-encode the whole
        -- reply_parameters object, so pre-encoding here double-encoded it
        -- into a JSON string on the wire.
        opts = opts or {}
        return {
            ['message_id'] = tonumber(message_id),
            ['chat_id'] = chat_id,
            ['allow_sending_without_reply'] = allow_sending_without_reply,
            ['quote'] = quote,
            ['quote_parse_mode'] = quote_parse_mode,
            ['quote_entities'] = quote_entities,
            ['quote_position'] = tonumber(quote_position),
            ['poll_option_id'] = opts.poll_option_id,
            ['checklist_task_id'] = opts.checklist_task_id
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

    --- create a paid reaction type object.
    -- @return table a reaction type object with type "paid"
    function api.reaction_type_paid()
        return { ['type'] = 'paid' }
    end

    -- Web app info

    function api.web_app_info(url)
        return { ['url'] = url }
    end

    -- Accepted gift types

    function api.accepted_gift_types(opts)
        opts = opts or {}
        return json_object({
            ['unlimited_gifts'] = opts.unlimited_gifts,
            ['limited_gifts'] = opts.limited_gifts,
            ['unique_gifts'] = opts.unique_gifts,
            ['premium_subscription'] = opts.premium_subscription,
            ['gifts_from_channels'] = opts.gifts_from_channels
        })
    end

    -- Suggested post parameters

    function api.suggested_post_parameters(opts)
        opts = opts or {}
        return json_object({
            ['star_count'] = opts.star_count,
            ['pay_for_sponsored_message'] = opts.pay_for_sponsored_message
        })
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
