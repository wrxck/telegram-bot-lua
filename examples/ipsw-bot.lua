local ipsw = {}

local api = require('telegram-bot-lua.core').configure('') -- Insert your token here.
local tools = require('telegram-bot-lua.tools')
local https = require('ssl.https')
local url = require('socket.url')
local json = require('dkjson')

function ipsw.init()
    ipsw.data = {}
    local jstr, res = https.request('https://api.ipsw.me/v2.1/firmwares.json')
    if res == 200 then
        ipsw.data = json.decode(jstr)
    end
    ipsw.devices = {}
    for k, v in pairs(ipsw.data.devices) do
        if k:lower():match('^appletv') then
            if not ipsw.devices['Apple TV'] then
                ipsw.devices['Apple TV'] = {}
            end
            table.insert(ipsw.devices['Apple TV'], k)
            table.sort(ipsw.devices['Apple TV'])
        elseif k:lower():match('^ipad') then
            if not ipsw.devices['iPad'] then
                ipsw.devices['iPad'] = {}
            end
            table.insert(ipsw.devices['iPad'], k)
            table.sort(ipsw.devices['iPad'])
        elseif k:lower():match('^ipod') then
            if not ipsw.devices['iPod'] then
                ipsw.devices['iPod'] = {}
            end
            table.insert(ipsw.devices['iPod'], k)
            table.sort(ipsw.devices['iPod'])
        elseif k:lower():match('^iphone') then
            if not ipsw.devices['iPhone'] then
                ipsw.devices['iPhone'] = {}
            end
            table.insert(ipsw.devices['iPhone'], k)
            table.sort(ipsw.devices['iPhone'])
        end
    end
end

function ipsw.get_info(input)
    local device = input
    local version = 'latest'
    if input:match('^.- .-$') then
        device = input:match('^(.-) ')
        version = input:match(' (.-)$')
    end
    local jstr, res = https.request(
        string.format(
            'https://api.ipsw.me/v2.1/%s/%s/info.json',
            url.escape(device),
            url.escape(version)
        )
    )
    if res ~= 200 or jstr == '[]' then
        return false
    end
    return json.decode(jstr)
end

function ipsw.get_model_keyboard(device)
    local keyboard = {
        ['inline_keyboard'] = {
            {}
        }
    }
    local total = 0
    for _, v in pairs(ipsw.devices[device]) do
        total = total + 1
    end
    local count = 0
    local rows = math.floor(total / 10)
    if rows ~= total then
        rows = rows + 1
    end
    local row = 1
    for k, v in pairs(ipsw.data.devices) do
        if k:lower():match(
            device:lower():gsub(' ', '')
        ) then
            count = count + 1
            if count == rows * row then
                row = row + 1
                table.insert(
                    keyboard.inline_keyboard,
                    {}
                )
            end
            table.insert(
                keyboard.inline_keyboard[row],
                {
                    ['text'] = v.name,
                    ['callback_data'] = 'model:' .. k
                }
            )
        end
    end
    return keyboard
end

function ipsw.get_firmware_keyboard(model)
    local keyboard = {
        ['inline_keyboard'] = {
            {}
        }
    }
    local total = 0
    for _, v in pairs(ipsw.data.devices[model].firmwares) do
        total = total + 1
    end
    local count = 0
    local rows = math.floor(total / 7)
    if rows ~= total then
        rows = rows + 1
    end
    local row = 1
    for k, v in pairs(ipsw.data.devices[model].firmwares) do
        count = count + 1
        if count == rows * row then
            row = row + 1
            table.insert(
                keyboard.inline_keyboard,
                {}
            )
        end
        table.insert(
            keyboard.inline_keyboard[row],
            {
                ['text'] = v.version,
                ['callback_data'] = 'firmware:' .. model .. ' ' .. v.buildid
            }
        )
    end
    return keyboard
end

function api.on_callback_query(callback_query)
    ipsw.init()
    local message = callback_query.message
    print(callback_query.data)
    if callback_query.data:match('^device%:') then
        callback_query.data = callback_query.data:match('^device%:(.-)$')
        return api.edit_message_text(
            message.chat.id,
            message.message_id,
            'Please select your model:',
            nil,
            true,
            ipsw.get_model_keyboard(callback_query.data)
        )
    elseif callback_query.data:match('^model%:') then
        callback_query.data = callback_query.data:match('^model%:(.-)$')
        return api.edit_message_text(
            message.chat.id,
            message.message_id,
            'Please select your firmware version:',
            nil,
            true,
            ipsw.get_firmware_keyboard(callback_query.data)
        )
    elseif callback_query.data:match('^firmware%:') then
        local jdat = ipsw.get_info(
            callback_query.data:match('^firmware%:(.-)$')
        )
        return api.edit_message_text(
            message.chat.id,
            message.message_id,
            string.format(
                '<b>%s</b> iOS %s\n\n<i>Uploaded on %s at %s</i>\n\n<code>MD5 sum: %s\nSHA1 sum: %s\nFile size: %s GB</code>\n\n<i>%s This firmware is %s being signed!</i>',
                jdat[1].device,
                jdat[1].version,
                jdat[1].uploaddate:match('^(.-)T'),
                jdat[1].uploaddate:match('T(.-)Z$'),
                jdat[1].md5sum,
                jdat[1].sha1sum,
                tools.round(
                    jdat[1].size / 1000000000,
                    2
                ),
                jdat[1].signed == false and utf8.char(10060) or utf8.char(9989),
                jdat[1].signed == false and 'no longer' or 'still'
            ),
            'html',
            true,
            api.inline_keyboard():row(
                api.row():url_button(
                    jdat[1].filename,
                    jdat[1].url
                )
            )
        )
    end
end

function api.on_message(message)
    ipsw.init()
    return api.send_message(
        message.chat.id,
        'This tool was created by @wrxck, and makes use of the IPSW.me API.\nBefore we begin, please select your device type:',
        nil,
        true,
        false,
        nil,
        api.inline_keyboard():row(
            api.row():callback_data_button(
                'iPod Touch',
                'device:iPod'
            ):callback_data_button(
                'iPhone',
                'device:iPhone'
            )
        ):row(
            api.row():callback_data_button(
                'iPad',
                'device:iPad'
            ):callback_data_button(
                'Apple TV',
                'device:Apple TV'
            )
        )
    )
end

api.run()