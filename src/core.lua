--[[
    Copyright 2017 Matthew Hesketh <wrxck0@gmail.com>
    This code is licensed under the GPLv3. See /LICENSE for details.
]]

local api = {}

local https = require('ssl.https')
local multipart = require('multipart-post')
local ltn12 = require('ltn12')
local json = require('dkjson')

function api.configure(token, debug)
    if not token or type(token) ~= 'string' then
        token = nil
    end
    api.debug = debug and true or false
    api.token = assert(
        token,
        'Please specify your bot API token you received from @BotFather!'
    )
    repeat
        api.info = api.get_me()
    until api.info.result
    api.info = api.info.result
    api.info.name = api.info.first_name
    return api
end

function api.request(endpoint, parameters, file)
    assert(
        endpoint,
        'You must specify an endpoint to make this request to!'
    )
    parameters = parameters or {}
    for k, v in pairs(parameters) do
        parameters[k] = tostring(v)
    end
    if api.debug then
        print(
            json.encode(
                parameters,
                {
                    ['indent'] = true
                }
            )
        )
    end
    if file and next(file) ~= nil then
        local file_type, file_name = next(file)
        if not file_name then
            return false
        end
        if file_name:match('^%/[Tt][Mm][Pp]%/') then
            local file_res = io.open(
                file_name,
                'r'
            )
            local file_data = {
                filename = file_name,
                data = file_res:read('*a')
            }
            file_res:close()
            parameters[file_type] = file_data
        else
            local file_type, file_name = next(file)
            parameters[file_type] = file_name
        end
    end
    if next(parameters) == nil then
        parameters = {
            ''
        }
    end
    local response = {}
    local body, boundary = multipart.encode(parameters)
    local success, code = https.request(
        {
            ['url'] = endpoint,
            ['method'] = 'POST',
            ['headers'] = {
                ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
                ['Content-Length'] = #body
            },
            ['source'] = ltn12.source.string(body),
            ['sink'] = ltn12.sink.table(response)
        }
    )
    if not success then
        print(
            string.format(
                'Connection error [%s]',
                code
            )
        )
        return false, code
    end
    local jdat = table.concat(response)
    if not json.decode(jdat) then
        return jdat, code
    end
    jdat = json.decode(jdat)
    if jdat.ok == true then
        return jdat, code
    end
    print(
        string.format(
            '%s [%s]',
            jdat.description,
            jdat.error_code
        )
    )
    return false, jdat
end

function api.get_me()
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getMe',
            api.token
        )
    )
end

function api.get_updates(timeout, offset, limit, allowed_updates) -- https://core.telegram.org/bots/api#getupdates
    if type(allowed_updates) == 'table' then
        allowed_updates = json.encode(allowed_updates)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getUpdates',
            api.token
        ),
        {
            ['timeout'] = timeout,
            ['offset'] = offset,
            ['limit'] = limit,
            ['allowed_updates'] = allowed_updates
        }
    )
end

function api.send_message(message, text, parse_mode, disable_web_page_preview, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendmessage
    if disable_web_page_preview == nil then
        disable_web_page_preview = true
    end
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    local chat_id = message
    if type(message) == 'table' then
        chat_id = message.chat.id
    end
    if type(parse_mode) == 'boolean' and parse_mode == true then
        parse_mode = 'markdown'
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendMessage',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['disable_web_page_preview'] = disable_web_page_preview,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.send_reply(message, text, parse_mode, disable_web_page_preview, reply_markup) -- A variant of api.send_message(), optimised for sending a message as a reply.
    if disable_web_page_preview == nil then
        disable_web_page_preview = true
    end
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    if type(parse_mode) == 'boolean' and parse_mode == true then
        parse_mode = 'markdown'
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendMessage',
            api.token
        ),
        {
            ['chat_id'] = message.chat.id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['disable_web_page_preview'] = disable_web_page_preview,
            ['disable_notification'] = false,
            ['reply_to_message_id'] = message.message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.forward_message(chat_id, from_chat_id, disable_notification, message_id) -- https://core.telegram.org/bots/api#forwardmessage
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/forwardMessage',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['from_chat_id'] = from_chat_id,
            ['disable_notification'] = disable_notification or false,
            ['message_id'] = message_id
        }
    )
end

function api.send_photo(chat_id, photo, caption, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendphoto
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendPhoto',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['photo'] = photo
        }
    )
end

function api.send_audio(chat_id, audio, caption, duration, performer, title, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendaudio
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendAudio',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption,
            ['duration'] = duration,
            ['performer'] = performer,
            ['title'] = title,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['audio'] = audio
        }
    )
end

function api.send_document(chat_id, document, caption, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#senddocument
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendDocument',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['document'] = document
        }
    )
end

function api.send_sticker(chat_id, sticker, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendsticker
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendSticker',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['sticker'] = sticker
        }
    )
end

function api.send_video(chat_id, video, duration, width, height, caption, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendvideo
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendVideo',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['duration'] = duration,
            ['width'] = width,
            ['height'] = height,
            ['caption'] = caption,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['video'] = video
        }
    )
end

function api.send_voice(chat_id, voice, caption, duration, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendvoice
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendVoice',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['caption'] = caption,
            ['duration'] = duration,
            ['disable_notification'] = disable_notification,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        },
        {
            ['voice'] = voice
        }
    )
end

function api.send_location(chat_id, latitude, longitude, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendlocation
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendLocation',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.send_venue(chat_id, latitude, longitude, title, address, foursquare_id, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendvenue
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendVenue',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['latitude'] = latitude,
            ['longitude'] = longitude,
            ['title'] = title,
            ['address'] = address,
            ['foursquare_id'] = foursquare_id,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.send_contact(chat_id, phone_number, first_name, last_name, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendcontact
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendContact',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['phone_number'] = phone_number,
            ['first_name'] = first_name,
            ['last_name'] = last_name,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.send_chat_action(chat_id, action) -- https://core.telegram.org/bots/api#sendchataction
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendChatAction',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['action'] = action or 'typing'
        }
    )
end

function api.get_user_profile_photos(user_id, offset, limit) -- https://core.telegram.org/bots/api#getuserprofilephotos
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getUserProfilePhotos',
            api.token
        ),
        {
            ['user_id'] = user_id,
            ['offset'] = offset,
            ['limit'] = limit
        }
    )
end

function api.get_file(file_id) -- https://core.telegram.org/bots/api#getfile
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getFile',
            api.token
        ),
        {
            ['file_id'] = file_id
        }
    )
end

function api.ban_chat_member(chat_id, user_id) -- https://core.telegram.org/bots/api#kickchatmember
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/kickChatMember',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
end

function api.kick_chat_member(chat_id, user_id)
    local success = api.request(
        string.format(
            'https://api.telegram.org/bot%s/kickChatMember',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
    if not success then
        return success
    end
    return api.unban_chat_member(
        chat_id,
        user_id,
        token
    )
end

function api.unban_chat_member(chat_id, user_id) -- https://core.telegram.org/bots/api#unbanchatmember
    local success
    for i = 1, 3 do
        success = api.request(
            string.format(
                'https://api.telegram.org/bot%s/unbanChatMember',
                api.token
            ),
            {
                ['chat_id'] = chat_id,
                ['user_id'] = user_id
            }
        )
    end
    return success
end

function api.leave_chat(chat_id) -- https://core.telegram.org/bots/api#leavechat
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/leaveChat',
            api.token
        ),
        {
            ['chat_id'] = chat_id
        }
    )
end

function api.get_chat_administrators(chat_id) -- https://core.telegram.org/bots/api#getchatadministrators
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getChatAdministrators',
            api.token
        ),
        {
            ['chat_id'] = chat_id
        }
    )
end

function api.get_chat_members_count(chat_id) -- https://core.telegram.org/bots/api#getchatmemberscount
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getChatMembersCount',
            api.token
        ),
        {
            ['chat_id'] = chat_id
        }
    )
end

function api.get_chat_member(chat_id, user_id) -- https://core.telegram.org/bots/api#getchatmember
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getChatMember',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        }
    )
end

function api.answer_callback_query(callback_query_id, text, show_alert, url, cache_time) -- https://core.telegram.org/bots/api#answercallbackquery
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/answerCallbackQuery',
            api.token
        ),
        {
            ['callback_query_id'] = callback_query_id,
            ['text'] = text,
            ['show_alert'] = show_alert or false,
            ['url'] = url,
            ['cache_time'] = cache_time
        }
    )
end

function api.edit_message_text(chat_id, message_id, text, parse_mode, disable_web_page_preview, reply_markup, inline_message_id) -- https://core.telegram.org/bots/api#editmessagetext
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    if type(parse_mode) == 'boolean' and parse_mode == true then
        parse_mode = 'markdown'
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/editMessageText',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id,
            ['text'] = text,
            ['parse_mode'] = parse_mode,
            ['disable_web_page_preview'] = disable_web_page_preview,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.edit_message_caption(chat_id, message_id, caption, reply_markup, inline_message_id) -- https://core.telegram.org/bots/api#editmessagecaption
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/editMessageCaption',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id,
            ['caption'] = caption,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.edit_message_reply_markup(chat_id, message_id, inline_message_id, reply_markup) -- https://core.telegram.org/bots/api#editmessagereplymarkup
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/editMessageReplyMarkup',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.answer_inline_query(inline_query_id, results, cache_time, is_personal, next_offset, switch_pm_text, switch_pm_parameter) -- https://core.telegram.org/bots/api#answerinlinequery
    if type(results) == 'table' then
        if results.id then
            results = {
                results
            }
        end
        results = json.encode(results)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/answerInlineQuery',
            api.token
        ),
        {
            ['inline_query_id'] = inline_query_id,
            ['results'] = results,
            ['switch_pm_text'] = switch_pm_text or 'More features!',
            ['switch_pm_parameter'] = switch_pm_parameter or 'help',
            ['cache_time'] = cache_time or 0,
            ['is_personal'] = is_personal or false,
            ['next_offset'] = next_offset
        }
    )
end

function api.send_game(chat_id, game_short_name, disable_notification, reply_to_message_id, reply_markup) -- https://core.telegram.org/bots/api#sendgame
    if type(reply_markup) == 'table' then
        reply_markup = json.encode(reply_markup)
    end
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/sendGame',
            api.token
        ),
        {
            ['chat_id'] = chat_id,
            ['game_short_name'] = game_short_name,
            ['disable_notification'] = disable_notification or false,
            ['reply_to_message_id'] = reply_to_message_id,
            ['reply_markup'] = reply_markup
        }
    )
end

function api.set_game_score(chat_id, user_id, message_id, score, force, disable_edit_message, inline_message_id) -- https://core.telegram.org/bots/api#setgamescore
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/setGameScore',
            api.token
        ),
        {
            ['user_id'] = user_id,
            ['score'] = score,
            ['force'] = force or false,
            ['disable_edit_message'] = disable_edit_message or false,
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id
        }
    )
end

function api.get_game_high_scores(chat_id, user_id, message_id, inline_message_id) -- https://core.telegram.org/bots/api#getgamehighscores
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getGameHighScores',
            api.token
        ),
        {
            ['user_id'] = user_id,
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['inline_message_id'] = inline_message_id
        }
    )
end

function api.get_chat(chat_id) -- https://core.telegram.org/bots/api#getchat
    return api.request(
        string.format(
            'https://api.telegram.org/bot%s/getChat',
            api.token
        ),
        {
            ['chat_id'] = chat_id
        }
    )
end

function api.on_update(update) end
function api.on_message(message) end
function api.on_callback_query(callback_query) end
function api.on_inline_query(inline_query) end
function api.on_channel_post(channel_post) end
function api.on_edited_message(edited_message) end
function api.on_edited_channel_post(edited_channel_post) end
function api.on_chosen_inline_result(chosen_inline_result) end

function api.process_update(update)
    if update then
        api.on_update(update)
    end
    if update.message then
        return api.on_message(update.message)
    elseif update.edited_message then
        return api.on_edited_message(update.edited_message)
    elseif update.callback_query then
        return api.on_callback_query(update.callback_query)
    elseif update.inline_query then
        return api.on_inline_query(update.inline_query)
    elseif update.channel_post then
        return api.on_channel_post(update.channel_post)
    elseif update.edited_channel_post then
        return api.on_edited_channel_post(update.edited_channel_post)
    elseif update.chosen_inline_result then
        return api.on_chosen_inline_result(update.chosen_inline_result)
    end
    return
end

function api.run(limit, timeout)
    limit = limit or 1
    timeout = timeout or 0
    offset = 0
    while true do
        local updates = api.get_updates(
            timeout,
            offset
        )
        if updates and updates.result then
            for k, v in pairs(updates.result) do
                api.process_update(v)
                offset = v.update_id + 1
            end
        end
    end
    return
end

function api.input_text_message_content(message_text, parse_mode, disable_web_page_preview, encoded)
    if type(parse_mode) == 'boolean' and parse_mode == true then
        parse_mode = 'markdown'
    end
    local input_message_content = {
        ['message_text'] = tostring(message_text),
        ['parse_mode'] = parse_mode,
        ['disable_web_page_preview'] = disable_web_page_preview
    }
    if encoded then
        input_message_content = json.encode(input_message_content)
    end
    return input_message_content
end

function api.input_location_message_content(latitude, longitude, encoded)
    local input_message_content = {
        ['latitude'] = tonumber(latitude),
        ['longitude'] = tonumber(longitude)
    }
    if encoded then
        input_message_content = json.encode(input_message_content)
    end
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
    if encoded then
        input_message_content = json.encode(input_message_content)
    end
    return input_message_content
end

function api.input_contact_message_content(phone_number, first_name, last_name, encoded)
    local input_message_content = {
        ['phone_number'] = tostring(phone_number),
        ['first_name'] = tonumber(first_name),
        ['last_name'] = last_name
    }
    if encoded then
        input_message_content = json.encode(input_message_content)
    end
    return input_message_content
end

--[[

    Functions for handling inline objects to use with api.answer_inline_query()

]]

function api.send_inline_article(inline_query_id, title, description, message_text, parse_mode, reply_markup)
    description = description or title
    message_text = message_text or description
    if type(parse_mode) == 'boolean' and parse_mode == true then
        parse_mode = 'markdown'
    end
    return api.answer_inline_query(
        inline_query_id,
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = '1',
                    ['title'] = title,
                    ['description'] = description,
                    ['input_message_content'] = {
                        ['message_text'] = message_text,
                        ['parse_mode'] = parse_mode
                    },
                    ['reply_markup'] = reply_markup
                }
            }
        )
    )
end

function api.send_inline_article_url(inline_query_id, title, url, hide_url, input_message_content, reply_markup, id)
    if id then
        id = tostring(id)
    end
    return api.answer_inline_query(
        inline_query_id,
        json.encode(
            {
                {
                    ['type'] = 'article',
                    ['id'] = id or '1',
                    ['title'] = tostring(title),
                    ['url'] = tostring(url),
                    ['hide_url'] = hide_url or false,
                    ['input_message_content'] = input_message_content,
                    ['reply_markup'] = reply_markup
                }
            }
        )
    )
end

api.inline_result_meta = {}

api.inline_result_meta.__index = api.inline_result_meta

function api.inline_result_meta:type(type)
    self['type'] = tostring(type)
    return self
end

function api.inline_result_meta:id(id)
    if id then
        id = tostring(id)
    end
    self['id'] = id or '1'
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

function api.inline_result_meta:thumb_url(thumb_url)
    self['thumb_url'] = tostring(thumb_url)
    return self
end

function api.inline_result_meta:thumb_width(thumb_width)
    self['thumb_width'] = tonumber(thumb_width)
    return self
end

function api.inline_result_meta:thumb_height(thumb_height)
    self['thumb_height'] = tonumber(thumb_height)
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
    local output = setmetatable(
        {},
        api.inline_result_meta
    )
    return output
end

function api.send_inline_photo(inline_query_id, photo_url, caption, reply_markup)
    return api.answer_inline_query(
        inline_query_id,
        json.encode(
            {
                {
                    ['type'] = 'photo',
                    ['id'] = '1',
                    ['photo_url'] = photo_url,
                    ['thumb_url'] = photo_url,
                    ['caption'] = caption,
                    ['reply_markup'] = reply_markup
                }
            }
        )
    )
end

function api.send_inline_cached_photo(inline_query_id, photo_file_id, caption, reply_markup)
    return api.answer_inline_query(
        inline_query_id,
        json.encode(
            {
                {
                    ['type'] = 'photo',
                    ['id'] = '1',
                    ['photo_file_id'] = photo_file_id,
                    ['caption'] = caption,
                    ['reply_markup'] = reply_markup
                }
            }
        )
    )
end

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

function api.remove_keyboard(selective)
    return {
        ['remove_keyboard'] = true,
        ['selective'] = selective or false
    }
end

api.keyboard_meta = {}
api.keyboard_meta.__index = api.keyboard_meta

function api.keyboard_meta:row(row)
    table.insert(
        self.keyboard,
        row
    )
    return self
end

function api.keyboard(resize_keyboard, one_time_keyboard, selective)
    return setmetatable(
        {
            ['keyboard'] = {},
            ['resize_keyboard'] = resize_keyboard or false,
            ['one_time_keyboard'] = one_time_keyboard or false,
            ['selective'] = selective or false
        },
        api.keyboard_meta
    )
end

api.inline_keyboard_meta = {}
api.inline_keyboard_meta.__index = api.inline_keyboard_meta

function api.inline_keyboard_meta:row(row)
    table.insert(
        self.inline_keyboard,
        row
    )
    return self
end

function api.inline_keyboard()
    return setmetatable(
        {
            ['inline_keyboard'] = {}
        },
        api.inline_keyboard_meta
    )
end

api.row_meta = {}
api.row_meta.__index = api.row_meta

function api.row_meta:url_button(text, url)
    table.insert(
        self,
        {
            ['text'] = tostring(text),
            ['url'] = tostring(url)
        }
    )
    return self
end

function api.row_meta:callback_data_button(text, callback_data)
    table.insert(
        self,
        {
            ['text'] = tostring(text),
            ['callback_data'] = tostring(callback_data)
        }
    )
    return self
end

function api.row_meta:switch_inline_query_button(text, switch_inline_query)
    table.insert(
        self,
        {
            ['text'] = tostring(text),
            ['switch_inline_query'] = tostring(switch_inline_query)
        }
    )
    return self
end

function api.row_meta:switch_inline_query_current_chat_button(text, switch_inline_query_current_chat)
    table.insert(
        self,
        {
            ['text'] = tostring(text),
            ['switch_inline_query_current_chat'] = tostring(switch_inline_query_current_chat)
        }
    )
    return self
end

function api.row(buttons)
    return setmetatable(
        {},
        api.row_meta
    )
end

return api