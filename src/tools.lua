--[[

       _       _                                      _           _          _
      | |     | |                                    | |         | |        | |
      | |_ ___| | ___  __ _ _ __ __ _ _ __ ___ ______| |__   ___ | |_ ______| |_   _  __ _
      | __/ _ \ |/ _ \/ _` | '__/ _` | '_ ` _ \______| '_ \ / _ \| __|______| | | | |/ _` |
      | ||  __/ |  __/ (_| | | | (_| | | | | | |     | |_) | (_) | |_       | | |_| | (_| |
       \__\___|_|\___|\__, |_|  \__,_|_| |_| |_|     |_.__/ \___/ \__|      |_|\__,_|\__,_|
                       __/ |
                      |___/

      Version 1.9-0
      Copyright (c) 2020 Matthew Hesketh
      See LICENSE for details

]]

local tools = {}
local api = require('telegram-bot-lua.core')
local https = require('ssl.https')
local http = require('socket.http')
local socket = require('socket')
local ltn12 = require('ltn12')
local json = require('dkjson')
local utf8 = utf8 or require('lua-utf8') -- Lua 5.2 compatibility.

function tools.comma_value(amount)
    amount = tostring(amount)
    local k
    while true do
        amount, k = amount:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then
            break
        end
    end
    return amount
end

function tools.format_ms(milliseconds)
    local total_seconds = math.floor(milliseconds / 1000)
    local seconds = total_seconds % 60
    local minutes = math.floor(total_seconds / 60) % 60
    local hours = math.floor(minutes / 60)
    return string.format('%02d:%02d:%02d', hours, minutes, seconds)
end

function tools.format_time(seconds)
    if not seconds or tonumber(seconds) == nil then
        return false
    end
    local output = ''
    seconds = tonumber(seconds) -- Make sure we're handling a numerical value
    local minutes = math.floor(seconds / 60)
    if minutes == 0 then
        return seconds ~= 1 and seconds .. ' seconds' or seconds .. ' second'
    elseif minutes < 60 then
        return minutes ~= 1 and minutes .. ' minutes' or minutes .. ' minute'
    end
    local hours = math.floor(seconds / 3600)
    if hours == 0 then
        return minutes ~= 1 and minutes .. ' minutes' or minutes .. ' minute'
    elseif hours < 24 then
        return hours ~= 1 and hours .. ' hours' or hours .. ' hour'
    end
    local days = math.floor(seconds / 86400)
    if days == 0 then
        return hours ~= 1 and hours .. ' hours' or hours .. ' hour'
    elseif days < 7 then
        return days ~= 1 and days .. ' days' or days .. ' day'
    end
    local weeks = math.floor(seconds / 604800)
    if weeks == 0 then
        return days ~= 1 and days .. ' days' or days .. ' day'
    else
        return weeks ~= 1 and weeks .. ' weeks' or weeks .. ' week'
    end
end

function tools.round(num, idp)
    if idp and idp > 0 then
        local mult = 10 ^ idp
        return math.floor(num * mult + .5) / mult
    end
    return math.floor(num + .5)
end

function tools.pretty_print(table)
    return json.encode(table, { ['indent'] = true })
end

tools.commands_meta = {}
tools.commands_meta.__index = tools.commands_meta

function tools.commands_meta:command(command)
    table.insert(self.table, '^[/!#]' .. command .. '$')
    table.insert(self.table, '^[/!#]' .. command .. '@' .. self.username .. '$')
    table.insert(self.table, '^[/!#]' .. command .. '%s+[^%s]*')
    table.insert(self.table, '^[/!#]' .. command .. '@' .. self.username .. '%s+[^%s]*')
    return self
end

function tools.commands(username, command_table)
    local self = setmetatable({}, tools.commands_meta)
    self.username = username
    self.table = command_table or {}
    return self
end

function tools.table_size(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
    end
    return i
end

function tools.escape_markdown(str)
    return tostring(str):gsub('_', '\\_'):gsub('%[', '\\['):gsub('*', '\\*'):gsub('`', '\\`')
end

function tools.escape_html(str)
    return tostring(str):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

function tools.escape_bash(str)
    return tostring(str):gsub('%$', ''):gsub('%^', ''):gsub('&', ''):gsub('|', ''):gsub(';', '')
end

function tools.utf8_len(str)
    local chars = 0
    for i = 1, str:len() do
        local byte = str:byte(i)
        if byte < 128 or byte >= 192 then
            chars = chars + 1
        end
    end
    return chars
end

function tools.get_linked_name(id)
    local success = api.get_chat(id)
    if not success or not success.result then
        return false
    end
    local output = tools.escape_html(success.result.first_name)
    if success.result.username then
        output = '<a href="https://t.me/' .. success.result.username .. '">' .. output .. '</a>'
    end
    return output
end

function tools.get_word(str, i)
    if not str then
        return false
    end
    i = i or 1
    local n = 1
    for word in str:gmatch('%g+') do
        if n == i then
            return word
        end
        n = n + 1
    end
    return false
end

function tools.input(s)
    if not s then
        return false
    end
    local input = s:find(' ')
    if not input then
        return false
    end
    return s:sub(input + 1)
end

function tools.trim(str)
    return str:gsub('^%s*(.-)%s*$', '%1')
end

tools.symbols = {
    ['back'] = utf8.char(8592),
    ['previous'] = utf8.char(8592),
    ['forward'] = utf8.char(8594),
    ['next'] = utf8.char(8594),
    ['bullet'] = utf8.char(8226),
    ['bullet_point'] = utf8.char(8226)
}

function tools.create_link(text, link, parse_mode)
    text = tostring(text)
    parse_mode = parse_mode == true and 'markdown' or tostring(parse_mode)
    if not link then
        return text
    elseif parse_mode:lower() == 'markdown' then
        return '[' .. tools.escape_markdown(text) .. '](' .. tools.escape_markdown(link) .. ')'
    end
    return '<a href="' .. tools.escape_html(link) .. '">' .. tools.escape_html(text) .. '</a>'
end

function tools.download_file(url, name, path)
    name = name or os.time() .. '.' .. url:match('.+%/%.(.-)$')
    local body = {}
    local protocol = url:match('^https') and https or http
    local redirect = url:match('^https') and false or true
    local _, res = protocol.request(
        {
            ['url'] = url,
            ['sink'] = ltn12.sink.table(body),
            ['redirect'] = redirect
        }
    )
    if res ~= 200 then
        print(res)
        return false
    end
    path = path and tostring(path) or '/tmp/'
    if not path:match('^/') then
        path = '/' .. path
    end
    if not path:match('/$') then
        path = path .. '/'
    end
    local file = io.open(path .. name, 'w+')
    local contents = table.concat(body)
    file:write(contents)
    file:close()
    path = path .. name
    return path
end

function tools.save_to_file(data, filename, append)
    if not data or not filename then
        return false
    end
    local mode = append and 'a+' or 'w+'
    if not filename:match('^/') then
        filename = '/tmp/' .. filename
    end
    local file = io.open(filename, append)
    file:write(data)
    file:close()
    return filename
end

function tools.file_exists(path)
    local file = io.open(path, 'rb')
    if file then
        file:close()
    end
    return file ~= nil
end

function tools.get_file_as_table(path)
    if not path or not tools.file_exists(path) then
        return {}
    end
    local file = {}
    for line in io.lines(file) do
        file[#file + 1] = line
    end
    return file
end

function tools.read_file(path)
    if not path then
        return false
    end
    local file = io.open(path, 'rb')
    if not file then
        return false
    end
    local data = file:read('*all')
    file:close()
    return data
end

function tools.json_to_table(path)
    if not path then
        return {}
    end
    local parsed = tools.read_file(path)
    if not parsed then
        return {}
    end
    parsed = json.decode(parsed)
    return type(parsed) == 'table' and parsed or {}
end

function tools.get_formatted_user(user_id, name, parse_mode)
    if not user_id or not name then
        return false
    end
    if not parse_mode or type(parse_mode) == ('nil' or 'boolean') then
        parse_mode = 'markdown'
    end
    local user_id_string = '[%s](tg://user?id=%s)'
    if parse_mode:lower() == 'html' then
        user_id_string = '<a href="tg://user?id=%s">%s</a>'
        return string.format(user_id_string, user_id, tools.escape_html(name))
    end
    return string.format(user_id_string, tools.escape_markdown(name), user_id)
end


tools.random_string_charset = {}

for i = 65, 90 do
    table.insert(tools.random_string_charset, string.char(i))
end

for i = 97, 122 do
    table.insert(tools.random_string_charset, string.char(i))
end

function tools.random_string(length, amount)
    if not length or tonumber(length) <= 0 then
        return ''
    end
    local command = io.popen('shuf -i 1-100000 -n 1') -- uses shuf for another random value because everything in lua is shocking
    local seed = command:read('*all')
    command:close()
    seed = tonumber(seed) * socket.gettime()
    math.randomseed(seed)
    if amount and tonumber(amount) ~= nil then
        local output = {}
        for i = 1, tonumber(amount) do
            local value = tools.random_string(length - 1) .. tools.random_string_charset[math.random(1, #tools.random_string_charset)]
            table.insert(output, value)
        end
        return output
    end
    return tools.random_string(length - 1) .. tools.random_string_charset[math.random(1, #tools.random_string_charset)]
end

function tools.string_hexdump(data, length, size, space)
    data = tostring(data)
    size = (tonumber(size) == nil or tonumber(size) < 1) and 1 or tonumber(size)
    space = (tonumber(space) == nil or tonumber(space) < 1) and 8 or tonumber(space)
    length = (tonumber(length) == nil or tonumber(length) < 1) and 32 or tonumber(length)
    local output = {}
    local column = 0
    for i = 1, #data, size do
        for j = size, 1, -1 do
            local sub = string.sub(data, i + j - 1, i + j - 1)
            if #sub > 0 then
                local byte = string.byte(sub)
                local formatted = string.format('%.2x', byte)
                table.insert(output, formatted)
            end
        end
        if column % space == 0 then
            table.insert(output, ' ')
        end
        if (i + size - 1) % length == 0 then
            table.insert(output, '\n')
        end
        column = column + 1
    end
    return table.concat(output)
end

function tools.table_contains(tab, match)
    for _, val in pairs(tab) do
        if val == match then
            return true
        end
    end
    return false
end

function tools.table_random(tab, seed)
    if seed and tonumber(seed) ~= nil then
        math.randomseed(seed)
    end
    tab = type(tab) == 'table' and tab or { tostring(tab) }
    local total = 0
    for key, chance in pairs(tab) do
        total = total + chance
    end
    local choice = math.random() * total
    for key, chance in pairs(tab) do
        choice = choice - chance
        if choice < 0 then
            return key
        end
    end
end

function tools.get_word(str, i)
    if not str then
        return false
    end
    local n = 1
    for word in str:gmatch('%g+') do
        i = i or 1
        if n == i then
            return word
        end
        n = n + 1
    end
    return false
end

function tools.service_message(message)
    if message.new_chat_member then
        return true, 'new_chat_member'
    elseif message.left_chat_member then
        return true, 'left_chat_member'
    elseif message.new_chat_title then
        return true, 'new_chat_title'
    elseif message.new_chat_photo then
        return true, 'new_chat_photo'
    elseif message.delete_chat_photo then
        return true, 'delete_chat_photo'
    elseif message.group_chat_created then
        return true, 'group_chat_created'
    elseif message.supergroup_chat_created then
        return true, 'supergroup_chat_created'
    elseif message.channel_chat_created then
        return true, 'channel_chat_created'
    elseif message.migrate_to_chat_id then
        return true, 'migrate_to_chat_id'
    elseif message.migrate_from_chat_id then
        return true, 'migrate_from_chat_id'
    elseif message.pinned_message then
        return true, 'pinned_message'
    elseif message.successful_payment then
        return true, 'successful_payment'
    end
    return false
end

function tools.is_media(message)
    if message.audio or message.document or message.game or message.photo or message.sticker or message.video or message.voice or message.video_note or message.contact or message.location or message.venue or message.invoice then
        return true
    end
    return false
end

function tools.media_type(message)
    if message.audio then
        return 'audio'
    elseif message.document then
        return 'document'
    elseif message.game then
        return 'game'
    elseif message.photo then
        return 'photo'
    elseif message.sticker then
        return 'sticker'
    elseif message.video then
        return 'video'
    elseif message.voice then
        return 'voice'
    elseif message.video_note then
        return 'video note'
    elseif message.contact then
        return 'contact'
    elseif message.location then
        return 'location'
    elseif message.venue then
        return 'venue'
    elseif message.invoice then
        return 'invoice'
    elseif message.forward_from or message.forward_from_chat then
        return 'forwarded'
    elseif message.dice then
        return 'dice'
    elseif message.poll then
        return 'poll'
    elseif message.text then
        return (message.text:match('[\216-\219][\128-\191]') or message.text:match(utf8.char(0x202e)) or message.text:match(utf8.char(0x200f))) and 'rtl' or 'text'
    end
    return ''
end

function tools.file_id(message, unique_sticker)
    if message.audio then
        return message.audio.file_id
    elseif message.document then
        return message.document.file_id
    elseif message.sticker then
        if unique_sticker then
            return message.sticker.file_unique_id
        end
        return message.sticker.file_id
    elseif message.video then
        return message.video.file_id
    elseif message.voice then
        return message.voice.file_id
    elseif message.video_note then
        return message.video_note.file_id
    end
    return ''
end

return tools