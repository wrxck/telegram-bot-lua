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

]] local api = {}
local https = require('ssl.https')
local multipart = require('multipart-post')
local ltn12 = require('ltn12')
local json = require('dkjson')
local config = require('telegram-bot-lua.config')

api.version = '3.0-0'

function api.configure(token, debug)
    if not token or type(token) ~= 'string' then
        token = nil
    end
    api.debug = debug and true or false
    api.token = assert(token, 'Please specify your bot API token you received from @BotFather!')
    local max_retries = 5
    for i = 1, max_retries do
        api.info = api.get_me()
        if api.info and api.info.result then
            break
        end
        if i == max_retries then
            error('Failed to connect to Telegram API after ' .. max_retries .. ' attempts. Check your token and network.')
        end
        if _G._TEST then break end
        os.execute('sleep 1')
    end
    if api.info and api.info.result then
        api.info = api.info.result
        api.info.name = api.info.first_name
    end
    return api
end

function api.request(endpoint, parameters, file)
    assert(endpoint, 'You must specify an endpoint to make this request to!')
    parameters = parameters or {}
    for k, v in pairs(parameters) do
        parameters[k] = tostring(v)
    end
    if api.debug then
        local safe = {}
        for k, v in pairs(parameters) do safe[k] = v end
        local output = json.encode(safe, { ['indent'] = true })
        print(output)
    end
    if file and next(file) ~= nil then
        local file_type, file_name = next(file)
        if type(file_name) == 'string' then
            local file_res = io.open(file_name, 'rb')
            if file_res then
                parameters[file_type] = {
                    filename = file_name,
                    data = file_res:read('*a')
                }
                file_res:close()
            else
                parameters[file_type] = file_name
            end
        else
            parameters[file_type] = file_name
        end
    end
    parameters = next(parameters) == nil and {''} or parameters
    local response = {}
    local body, boundary = multipart.encode(parameters)
    local success, res = https.request({
        ['url'] = endpoint,
        ['method'] = 'POST',
        ['headers'] = {
            ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
            ['Content-Length'] = #body
        },
        ['source'] = ltn12.source.string(body),
        ['sink'] = ltn12.sink.table(response)
    })
    if not success then
        print('Connection error [' .. tostring(res) .. ']')
        return false, res
    end
    local jstr = table.concat(response)
    local jdat = json.decode(jstr)
    if not jdat then
        return false, res
    elseif not jdat.ok then
        if api.debug then
            local output = '\n' .. tostring(jdat.description) .. ' [' .. tostring(jdat.error_code) .. ']\n'
            print(output)
        end
        return false, jdat
    end
    return jdat, res
end

function api.get_me()
    local success, res = api.request(config.endpoint .. api.token .. '/getMe')
    return success, res
end

function api.log_out()
    local success, res = api.request(config.endpoint .. api.token .. '/logOut')
    return success, res
end

function api.close()
    local success, res = api.request(config.endpoint .. api.token .. '/close')
    return success, res
end

-- Load all modules
require('telegram-bot-lua.handlers')(api)
require('telegram-bot-lua.builders')(api)
require('telegram-bot-lua.helpers')(api)
require('telegram-bot-lua.methods.updates')(api)
require('telegram-bot-lua.methods.messages')(api)
require('telegram-bot-lua.methods.chat')(api)
require('telegram-bot-lua.methods.members')(api)
require('telegram-bot-lua.methods.forum')(api)
require('telegram-bot-lua.methods.stickers')(api)
require('telegram-bot-lua.methods.inline')(api)
require('telegram-bot-lua.methods.payments')(api)
require('telegram-bot-lua.methods.games')(api)
require('telegram-bot-lua.methods.passport')(api)
require('telegram-bot-lua.methods.bot')(api)
require('telegram-bot-lua.methods.gifts')(api)
require('telegram-bot-lua.methods.checklists')(api)
require('telegram-bot-lua.methods.stories')(api)
require('telegram-bot-lua.methods.suggested_posts')(api)
require('telegram-bot-lua.utils')(api)
require('telegram-bot-lua.async')(api)
require('telegram-bot-lua.adapters')(api)
require('telegram-bot-lua.compat')(api)

return api
