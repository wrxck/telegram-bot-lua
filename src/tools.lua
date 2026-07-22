--[[

       _       _                                      _           _          _
      | |     | |                                    | |         | |        | |
      | |_ ___| | ___  __ _ _ __ __ _ _ __ ___ ______| |__   ___ | |_ ______| |_   _  __ _
      | __/ _ \ |/ _ \/ _` | '__/ _` | '_ ` _ \______| '_ \ / _ \| __|______| | | | |/ _` |
      | ||  __/ |  __/ (_| | | | (_| | | | | | |     | |_) | (_) | |_       | | |_| | (_| |
       \__\___|_|\___|\__, |_|  \__,_|_| |_| |_|     |_.__/ \___/ \__|      |_|\__,_|\__,_|
                       __/ |
                      |___/

      Version 3.0-0
      Copyright (c) 2017-2026 Matthew Hesketh
      See LICENSE for details

]] local tools = {}
local https = require('ssl.https')
local http = require('socket.http')
local socket = require('socket')
local ltn12 = require('ltn12')
local json = require('dkjson')
local utf8 = utf8 or require('lua-utf8')
local b64url = require('telegram-bot-lua.b64url')
local poly = require('telegram-bot-lua.polyfill')
local band, lshift, rshift = poly.band, poly.lshift, poly.rshift
local sunpack = poly.string_unpack

--- format a number with comma-separated thousands.
-- @param amount number|string the number to format
-- @return string the comma-formatted number string
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

--- format milliseconds into HH:MM:SS string.
-- @param milliseconds number the duration in milliseconds
-- @return string the formatted time string in HH:MM:SS format
function tools.format_ms(milliseconds)
    local total_seconds = math.floor(milliseconds / 1000)
    local seconds = total_seconds % 60
    local minutes = math.floor(total_seconds / 60) % 60
    local hours = math.floor(total_seconds / 3600)
    return string.format('%02d:%02d:%02d', hours, minutes, seconds)
end

--- format seconds into a human-readable time string (e.g. "5 minutes", "2 hours").
-- returns the largest appropriate time unit.
-- @param seconds number the duration in seconds
-- @return string|boolean the formatted time string, or false if input is invalid
function tools.format_time(seconds)
    if not seconds or tonumber(seconds) == nil then
        return false
    end
    seconds = tonumber(seconds)
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

--- round a number to the specified number of decimal places.
-- @param num number the number to round
-- @param idp number optional number of decimal places (defaults to 0)
-- @return number the rounded number
function tools.round(num, idp)
    if idp and idp > 0 then
        local mult = 10 ^ idp
        return math.floor(num * mult + .5) / mult
    end
    return math.floor(num + .5)
end

--- encode a table as a pretty-printed JSON string.
-- @param tbl table the table to encode
-- @return string the indented JSON string
function tools.pretty_print(tbl)
    return json.encode(tbl, {
        ['indent'] = true
    })
end

tools.commands_meta = {}
tools.commands_meta.__index = tools.commands_meta

--- add a command pattern to the commands table, including variants with and without bot username.
-- @param command string the command name (without prefix)
-- @return table self for method chaining
function tools.commands_meta:command(command)
    table.insert(self.table, '^[/!#]' .. command .. '$')
    table.insert(self.table, '^[/!#]' .. command .. '@' .. self.username .. '$')
    table.insert(self.table, '^[/!#]' .. command .. '%s+[^%s]*')
    table.insert(self.table, '^[/!#]' .. command .. '@' .. self.username .. '%s+[^%s]*')
    return self
end

--- create a new commands builder for matching bot commands.
-- @param username string the bot username used in command patterns
-- @param command_table table optional existing table to append patterns to
-- @return table a commands builder with a :command() method for chaining
function tools.commands(username, command_table)
    local self = setmetatable({}, tools.commands_meta)
    self.username = username
    self.table = command_table or {}
    return self
end

--- count the number of entries in a table (including non-sequential keys).
-- @param t table the table to count
-- @return number the number of key-value pairs
function tools.table_size(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
    end
    return i
end

--- escape special markdown characters in a string (v1 markdown).
-- @param str string the string to escape
-- @return string the escaped string
function tools.escape_markdown(str)
    return tostring(str):gsub('_', '\\_'):gsub('%[', '\\['):gsub('*', '\\*'):gsub('`', '\\`')
end

--- escape special MarkdownV2 characters in a string.
-- @param str string the string to escape
-- @return string the escaped string
function tools.escape_markdown_v2(str)
    return tostring(str):gsub('([_%*%[%]%(%)~`>#+%-%=|{}.!\\])', '\\%1')
end

--- escape special HTML characters (&, <, >) in a string.
-- @param str string the string to escape
-- @return string the escaped string
function tools.escape_html(str)
    return tostring(str):gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

--- escape a string for safe use in a bash single-quoted context.
-- @param str string the string to escape
-- @return string the escaped string wrapped in single quotes
function tools.escape_bash(str)
    return "'" .. tostring(str):gsub("'", "'\\''") .. "'"
end

--- count the number of UTF-8 characters in a string.
-- @param str string the string to measure
-- @return number the number of UTF-8 characters
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

--- get an HTML-formatted linked name for a user by their ID.
-- fetches the user's chat info and returns their first name as an HTML link if they have a username.
-- @param id number the user or chat ID
-- @return string|boolean the HTML-formatted name, or false on failure
function tools.get_linked_name(id)
    local api = require('telegram-bot-lua')
    local success = api.get_chat(id)
    if not success or not success.result then
        return false
    end
    local output = tools.escape_html(success.result.first_name)
    if success.result.username then
        output = '<a href="https://t.me/' .. tools.escape_html(success.result.username) .. '">' .. output .. '</a>'
    end
    return output
end

--- get the i-th whitespace-delimited word from a string.
-- @param str string the input string
-- @param i number optional word index (defaults to 1)
-- @return string|boolean the matched word, or false if not found
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

--- extract the text after the first space in a string (i.e. command input).
-- @param s string the input string
-- @return string|boolean the text after the first space, or false if none
function tools.input(s)
    if not s then
        return false
    end
    local pos = s:find(' ')
    if not pos then
        return false
    end
    return s:sub(pos + 1)
end

--- strip leading and trailing whitespace from a string.
-- @param str string the string to trim
-- @return string the trimmed string
function tools.trim(str)
    local result = str:gsub('^%s*(.-)%s*$', '%1')
    return result
end

tools.symbols = {
    ['back'] = utf8.char(8592),
    ['previous'] = utf8.char(8592),
    ['forward'] = utf8.char(8594),
    ['next'] = utf8.char(8594),
    ['bullet'] = utf8.char(8226),
    ['bullet_point'] = utf8.char(8226)
}

--- create a formatted hyperlink for the given parse mode.
-- supports markdown, markdownv2, and HTML (default).
-- @param text string the display text
-- @param link string the URL to link to
-- @param parse_mode string|boolean the parse mode ('markdown', 'markdownv2', or HTML by default; true means 'markdown')
-- @return string the formatted link string
function tools.create_link(text, link, parse_mode)
    text = tostring(text)
    parse_mode = parse_mode == true and 'markdown' or tostring(parse_mode)
    if not link then
        return text
    elseif parse_mode:lower() == 'markdown' then
        return '[' .. tools.escape_markdown(text) .. '](' .. tostring(link) .. ')'
    elseif parse_mode:lower() == 'markdownv2' then
        return '[' .. tools.escape_markdown_v2(text) .. '](' .. tostring(link):gsub('[%)\\]', '\\%1') .. ')'
    end
    return '<a href="' .. tools.escape_html(link) .. '">' .. tools.escape_html(text) .. '</a>'
end

local function sanitize_filename(name)
    return name:gsub('%.%.', ''):gsub('[/\\]', ''):gsub('%z', '')
end

--- download a file from a URL and save it to disk.
-- @param url string the URL to download from
-- @param name string optional filename (defaults to timestamp with extension from URL)
-- @param path string optional directory path to save to (defaults to /tmp/)
-- @return string|boolean the full file path on success, or false on failure
-- @return number|string the HTTP status code or error message on failure
function tools.download_file(url, name, path)
    if not name then
        local ext = url:match('%.([%w]+)$') or 'bin'
        name = tostring(os.time()) .. '.' .. ext
    end
    name = sanitize_filename(name)
    local body = {}
    local _, res
    if url:match('^https') then
        _, res = https.request({
            ['url'] = url,
            ['sink'] = ltn12.sink.table(body)
        })
    else
        _, res = http.request({
            ['url'] = url,
            ['sink'] = ltn12.sink.table(body),
            ['redirect'] = true
        })
    end
    if res ~= 200 then
        return false, res
    end
    path = path and tostring(path) or '/tmp/'
    if not path:match('^/') then
        path = '/tmp/' .. path
    end
    if not path:match('/$') then
        path = path .. '/'
    end
    local file = io.open(path .. name, 'wb')
    if not file then
        return false, 'Could not open file for writing'
    end
    local contents = table.concat(body)
    file:write(contents)
    file:close()
    path = path .. name
    return path
end

--- save data to a file in /tmp/.
-- @param data string the data to write
-- @param filename string the filename to write to (saved under /tmp/)
-- @param append boolean optional flag to append instead of overwrite
-- @return string|boolean the full file path on success, or false on failure
function tools.save_to_file(data, filename, append)
    if not data or not filename then
        return false
    end
    filename = sanitize_filename(filename)
    local mode = append and 'a+' or 'w+'
    local full_path = '/tmp/' .. filename
    local file = io.open(full_path, mode)
    if not file then
        return false
    end
    file:write(data)
    file:close()
    return full_path
end

--- check whether a file exists at the given path.
-- @param path string the file path to check
-- @return boolean true if the file exists, false otherwise
function tools.file_exists(path)
    local file = io.open(path, 'rb')
    if file then
        file:close()
    end
    return file ~= nil
end

--- read a file and return its lines as a table.
-- @param path string the file path to read
-- @return table a sequential table of lines (empty table if file not found)
function tools.get_file_as_table(path)
    if not path or not tools.file_exists(path) then
        return {}
    end
    local lines = {}
    for line in io.lines(path) do
        lines[#lines + 1] = line
    end
    return lines
end

--- read the entire contents of a file as a string.
-- @param path string the file path to read
-- @return string|boolean the file contents, or false on failure
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

--- read a JSON file and decode it into a lua table.
-- @param path string the file path to the JSON file
-- @return table the decoded table (empty table if file not found or invalid)
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

--- format a user mention link with the given parse mode.
-- generates a tg://user?id= deep link for mentioning users by ID.
-- @param user_id number the user's ID
-- @param name string the display name
-- @param parse_mode string the parse mode ('html', 'markdownv2', or markdown; defaults to 'MarkdownV2')
-- @return string|boolean the formatted user mention string, or false if missing params
function tools.get_formatted_user(user_id, name, parse_mode)
    if not user_id or not name then
        return false
    end
    if not parse_mode or type(parse_mode) == 'nil' or type(parse_mode) == 'boolean' then
        parse_mode = 'MarkdownV2'
    end
    local user_id_string = '[%s](tg://user?id=%s)'
    if parse_mode:lower() == 'html' then
        user_id_string = '<a href="tg://user?id=%s">%s</a>'
        return string.format(user_id_string, user_id, tools.escape_html(name))
    elseif parse_mode:lower() == 'markdownv2' then
        return string.format(user_id_string, tools.escape_markdown_v2(name), user_id)
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

for i = 48, 57 do
    table.insert(tools.random_string_charset, string.char(i))
end

do
    local seeded = false
    --- generate one or more random alphanumeric strings of a given length.
    -- @param length number the length of each random string
    -- @param amount number optional number of strings to generate
    -- @return string|table a single string if amount is nil, or a table of strings
    function tools.random_string(length, amount)
        length = tonumber(length)
        if not length or length <= 0 then
            return ''
        end
        if not seeded then
            math.randomseed(os.time() + math.floor(socket.gettime() * 1000) % 1000000)
            seeded = true
        end
        local function generate()
            local chars = {}
            for _ = 1, length do
                chars[#chars + 1] = tools.random_string_charset[math.random(1, #tools.random_string_charset)]
            end
            return table.concat(chars)
        end
        if amount and tonumber(amount) ~= nil then
            local output = {}
            for _ = 1, tonumber(amount) do
                table.insert(output, generate())
            end
            return output
        end
        return generate()
    end
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
        column = column + 1
        if column % space == 0 then
            table.insert(output, ' ')
        end
        if (i + size - 1) % length == 0 then
            table.insert(output, '\n')
        end
    end
    return table.concat(output)
end

function tools.table_contains(tab, match)
    if type(tab) ~= 'table' then
        return false
    end
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
    tab = type(tab) == 'table' and tab or {tostring(tab)}
    -- weighted map form: { option = chance, ... }. if any value is not a
    -- number, fall back to picking one of the values with equal probability
    -- (the plain-array / scalar form used to crash on `total + chance`).
    local total = 0
    for _, chance in pairs(tab) do
        if type(chance) ~= 'number' then
            local values = {}
            for _, value in pairs(tab) do
                values[#values + 1] = value
            end
            return values[math.random(#values)]
        end
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
    elseif message.forum_topic_created then
        return true, 'forum_topic_created'
    elseif message.forum_topic_edited then
        return true, 'forum_topic_edited'
    elseif message.forum_topic_closed then
        return true, 'forum_topic_closed'
    elseif message.forum_topic_reopened then
        return true, 'forum_topic_reopened'
    elseif message.general_forum_topic_hidden then
        return true, 'general_forum_topic_hidden'
    elseif message.general_forum_topic_unhidden then
        return true, 'general_forum_topic_unhidden'
    elseif message.video_chat_scheduled then
        return true, 'video_chat_scheduled'
    elseif message.video_chat_started then
        return true, 'video_chat_started'
    elseif message.video_chat_ended then
        return true, 'video_chat_ended'
    elseif message.video_chat_participants_invited then
        return true, 'video_chat_participants_invited'
    elseif message.web_app_data then
        return true, 'web_app_data'
    elseif message.write_access_allowed then
        return true, 'write_access_allowed'
    elseif message.proximity_alert_triggered then
        return true, 'proximity_alert_triggered'
    elseif message.users_shared then
        return true, 'users_shared'
    elseif message.chat_shared then
        return true, 'chat_shared'
    elseif message.giveaway_created then
        return true, 'giveaway_created'
    elseif message.giveaway then
        return true, 'giveaway'
    elseif message.giveaway_winners then
        return true, 'giveaway_winners'
    elseif message.giveaway_completed then
        return true, 'giveaway_completed'
    elseif message.boost_added then
        return true, 'boost_added'
    elseif message.chat_background_set then
        return true, 'chat_background_set'
    elseif message.paid_media_purchased then
        return true, 'paid_media_purchased'
    end
    return false
end

function tools.is_media(message)
    if message.audio or message.document or message.game or message.photo or message.sticker or message.video or
        message.animation or message.voice or message.video_note or message.contact or message.location or
        message.venue or message.invoice or message.poll or message.dice or message.paid_media then
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
    elseif message.animation then
        return 'animation'
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
    elseif message.paid_media then
        return 'paid_media'
    elseif message.forward_from or message.forward_from_chat then
        return 'forwarded'
    elseif message.dice then
        return 'dice'
    elseif message.poll then
        return 'poll'
    elseif message.text then
        return (message.text:match('[\216-\219][\128-\191]') or message.text:match(utf8.char(0x202e)) or
                   message.text:match(utf8.char(0x200f))) and 'rtl' or 'text'
    end
    return ''
end

function tools.file_id(message, unique)
    if message.audio then
        if unique then
            return message.audio.file_unique_id
        end
        return message.audio.file_id
    elseif message.document then
        if unique then
            return message.document.file_unique_id
        end
        return message.document.file_id
    elseif message.sticker then
        if unique then
            return message.sticker.file_unique_id
        end
        return message.sticker.file_id
    elseif message.video then
        if unique then
            return message.video.file_unique_id
        end
        return message.video.file_id
    elseif message.voice then
        if unique then
            return message.voice.file_unique_id
        end
        return message.voice.file_id
    elseif message.animation then
        if unique then
            return message.animation.file_unique_id
        end
        return message.animation.file_id
    elseif message.video_note then
        if unique then
            return message.video_note.file_unique_id
        end
        return message.video_note.file_id
    elseif message.photo then
        if unique then
            return message.photo[#message.photo].file_unique_id
        end
        return message.photo[#message.photo].file_id
    end
    return ''
end

function tools.is_duplicate(tab, val)
    local seen = {}
    local duplicated = {}
    for i = 1, #tab do
        local element = tab[i]
        if seen[element] then
            duplicated[element] = true
        else
            seen[element] = true
        end
    end
    if val and duplicated[val] then
        return true
    elseif val then
        return false
    end
    return duplicated
end

function tools.is_valid_url(original_url, parts, any)
    if not original_url then
        return false
    end
    original_url = tostring(original_url)
    if not original_url:match('^[Hh][Tt][Tt][Pp][Ss]?://') and not any then
        original_url = 'http://' .. original_url
    end
    local url, protocol, subdomain, tld, colon, port, slash, path = string.match(original_url,
        '^(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))$')
    if parts then
        return {
            ['url'] = url,
            ['protocol'] = protocol,
            ['subdomain'] = subdomain,
            ['tld'] = tld,
            ['colon'] = colon,
            ['port'] = port,
            ['slash'] = slash,
            ['path'] = path
        }
    end
    return url and true or false, url
end

function tools.file_size(file)
    local is_path = false
    if type(file) ~= 'userdata' and type(file) ~= 'string' then
        return false, 'No file/path given!'
    elseif type(file) == 'string' then
        is_path = true
        -- keep relative paths relative; forcing a leading '/' made every
        -- relative path unopenable.
        if file:match('/$') then
            file = file:match('^(.-)/$')
        end
        file = io.open(file, 'r')
        if not file then
            return false, 'Could not open file!'
        end
    end
    local current = file:seek()
    local size = file:seek('end')
    file:seek('set', current)
    if is_path then
        file:close()
    end
    return tonumber(size)
end

function tools.rle_encode(s)
    local new, count = '', 0
    local function flush()
        -- runs longer than 255 must be split across multiple markers, and a
        -- trailing run must be flushed or it is silently dropped.
        while count > 0 do
            local chunk = math.min(count, 255)
            new = new .. string.char(0) .. string.char(chunk)
            count = count - chunk
        end
    end
    for i = 1, #s do
        local current = s:sub(i, i)
        if current == string.char(0) then
            count = count + 1
        else
            flush()
            new = new .. current
        end
    end
    flush()
    return new
end

function tools.rle_decode(input)
    local new = ''
    local last = ''
    local length = #input
    for i = 1, length do
        local current = input:sub(i, i)
        if last == string.char(0) then
            new = new .. string.rep(last, string.byte(current))
            last = ''
        else
            new = new .. last
            last = current
        end
    end
    return new .. last
end

function tools.unpack_telegram_invite_link(link)
    if not link then
        return false, 'No link given!'
    elseif link:match('joinchat/') then
        link = link:match('joinchat/(.-)$')
    end
    local decoded = b64url.decode(link)
    if not decoded then
        return false, 'Could not decode!'
    end
    -- sunpack raises on payloads shorter than the format requires.
    local ok, user_id, chat_id, rand_long = pcall(sunpack, '>IIL', decoded)
    if not ok then
        return false, 'Could not unpack!'
    end
    return {
        ['user_id'] = user_id,
        ['chat_id'] = chat_id,
        ['rand_long'] = rand_long
    }
end

function tools.unpack_file_id(file_id, media_type)
    if not file_id then
        return false, 'No file_id given!'
    elseif not media_type then
        media_type = ''
    end
    local decoded = b64url.decode(file_id)
    if not decoded then
        return false, 'Could not decode!'
    end
    decoded = tools.rle_decode(decoded)
    -- parse under pcall: sunpack raises on payloads shorter than the format
    -- requires, and this function's contract is (false, err) on bad input.
    local pok, payload = pcall(function()
        local file_type = sunpack('<b', decoded)
        local dc_id = sunpack('<i', decoded:sub(5, 8))
        local file_flags = sunpack('<i', string.char(0) .. decoded:sub(2, 4))
        local version = string.byte(decoded:sub(-1))
        local subversion = (version == 4) and string.byte(decoded:sub(-2, -1)) or 0
        decoded = decoded:sub(9, -1)
        local file_reference_flag = lshift(1, 25)
        if band(file_flags, file_reference_flag) ~= 0 then
            local file_reference_length = string.byte(decoded:sub(1, 1))
            local padding
            decoded = string.char(0) .. decoded:sub(2, -1)
            if file_reference_length == 254 then
                file_reference_length = sunpack('<i', decoded)
                padding = math.abs(-file_reference_length % 4)
            else
                padding = math.abs(file_reference_length % -4)
            end
            decoded = decoded:sub(file_reference_length + padding + 1, -1)
        end
        local user_id, access_hash = sunpack('<ll', decoded)
        local result = {
            ['file_id'] = file_id,
            ['file_type'] = file_type,
            ['media_type'] = media_type,
            ['file_flags'] = file_flags,
            ['version'] = version,
            ['subversion'] = subversion,
            ['dc_id'] = dc_id,
            ['access_hash'] = access_hash
        }
        if media_type == 'photo' then
            local encrypted_user_id, new_access_hash, volume_id, secret, _, local_id = sunpack('<llllii', decoded)
            result.encrypted_user_id = encrypted_user_id
            result.access_hash = new_access_hash
            result.volume_id = volume_id
            result.secret = secret
            result.local_id = local_id
        elseif media_type == 'sticker' then
            result.user_id = rshift(user_id, 32)
        end
        return result
    end)
    if not pok then
        return false, 'Could not unpack!'
    end
    return payload
end

function tools.unpack_inline_message_id(inline_message_id)
    if not inline_message_id then
        return false, 'No inline_message_id given!'
    end
    local decoded = b64url.decode(inline_message_id)
    if not decoded then
        return false, 'Could not decode!'
    end
    -- layout: dc_id:int32, message_id:int32, chat_id:int32, access_hash:int64.
    -- the old '<iiI' format had only three items, so access_hash silently
    -- received string.unpack's next-position return value instead of data.
    local ok, dc_id, message_id, chat_id, access_hash = pcall(sunpack, '<i4i4i4i8', decoded)
    if not ok then
        return false, 'Could not unpack!'
    end
    return {
        ['dc_id'] = dc_id,
        ['message_id'] = message_id,
        ['chat_id'] = chat_id,
        ['access_hash'] = access_hash
    }
end

function tools.split_string(str, reverse)
    local tab = {}
    for prt in str:gmatch('([^%s]+)') do
        if reverse then
            table.insert(tab, 1, prt)
        else
            table.insert(tab, prt)
        end
    end
    return tab
end

function tools.string_array_to_table(string_array)
    local table_array = {}
    for part in string_array:gmatch('([^,]+),?') do
        table.insert(table_array, tools.trim(part))
    end
    return table_array
end

return tools
