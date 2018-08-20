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
      Copyright (c) 2017 Matthew Hesketh
      See LICENSE for details

]]

local tools = {}
local api = require('telegram-bot-lua.core')
local https = require('ssl.https')
local http = require('socket.http')
local ltn12 = require('ltn12')
local utf8 = utf8 or require('lua-utf8') -- Lua 5.2 compatibility.

function tools.comma_value(amount)
    amount = tostring(amount)
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
    return tostring(str):gsub('%_', '\\_'):gsub('%[', '\\['):gsub('%*', '\\*'):gsub('%`', '\\`')
end

function tools.escape_html(str)
    return tostring(str):gsub('%&', '&amp;'):gsub('%<', '&lt;'):gsub('%>', '&gt;')
end

function tools.escape_bash(str)
    return tostring(str):gsub('%$', ''):gsub('%^', ''):gsub('%&', ''):gsub('%|', ''):gsub('%;', '')
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

function tools.download_file(url, name, path)
    name = name or os.time() .. '.' .. url:match('.+%/%.(.-)$')
    local body = {}
    local protocol = http
    local redirect = true
    if url:match('^https') then
        protocol = https
        redirect = false
    end
    local _, res = protocol.request(
        {
            ['url'] = url,
            ['sink'] = ltn12.sink.table(body),
            ['redirect'] = redirect
        }
    )
    if res ~= 200 then
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
    local file_contents = table.concat(body)
    file:write(file_contents)
    file:close()
    path = path .. name
    return path
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

return tools