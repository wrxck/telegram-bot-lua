-- Test helper: sets up package paths and mocks for testing without network
_G._TEST = true

-- Set up package paths to find our modules
package.path = './src/?.lua;./src/?/init.lua;' .. package.path

-- Pre-register our module names to match rockspec mappings
local module_map = {
    ['telegram-bot-lua'] = 'src/init.lua',
    ['telegram-bot-lua.config'] = 'src/config.lua',
    ['telegram-bot-lua.handlers'] = 'src/handlers.lua',
    ['telegram-bot-lua.builders'] = 'src/builders.lua',
    ['telegram-bot-lua.helpers'] = 'src/helpers.lua',
    ['telegram-bot-lua.tools'] = 'src/tools.lua',
    ['telegram-bot-lua.utils'] = 'src/utils.lua',
    ['telegram-bot-lua.async'] = 'src/async.lua',
    ['telegram-bot-lua.compat'] = 'src/compat.lua',
    ['telegram-bot-lua.core'] = 'src/core.lua',
    ['telegram-bot-lua.polyfill'] = 'src/polyfill.lua',
    ['telegram-bot-lua.b64url'] = 'src/b64url.lua',
    ['telegram-bot-lua.methods.updates'] = 'src/methods/updates.lua',
    ['telegram-bot-lua.methods.messages'] = 'src/methods/messages.lua',
    ['telegram-bot-lua.methods.chat'] = 'src/methods/chat.lua',
    ['telegram-bot-lua.methods.members'] = 'src/methods/members.lua',
    ['telegram-bot-lua.methods.forum'] = 'src/methods/forum.lua',
    ['telegram-bot-lua.methods.stickers'] = 'src/methods/stickers.lua',
    ['telegram-bot-lua.methods.inline'] = 'src/methods/inline.lua',
    ['telegram-bot-lua.methods.payments'] = 'src/methods/payments.lua',
    ['telegram-bot-lua.methods.games'] = 'src/methods/games.lua',
    ['telegram-bot-lua.methods.passport'] = 'src/methods/passport.lua',
    ['telegram-bot-lua.methods.bot'] = 'src/methods/bot.lua',
    ['telegram-bot-lua.methods.gifts'] = 'src/methods/gifts.lua',
    ['telegram-bot-lua.methods.checklists'] = 'src/methods/checklists.lua',
    ['telegram-bot-lua.methods.stories'] = 'src/methods/stories.lua',
    ['telegram-bot-lua.methods.suggested_posts'] = 'src/methods/suggested_posts.lua',
}

for mod_name, file_path in pairs(module_map) do
    if not package.preload[mod_name] then
        package.preload[mod_name] = function()
            return dofile(file_path)
        end
    end
end

-- Mock api.request so we don't need a real token/network
local api = require('telegram-bot-lua')
api.token = 'test:TOKEN'
api.info = { id = 123456, first_name = 'TestBot', username = 'test_bot', is_bot = true }
api.info.name = api.info.first_name

-- Store request calls for assertions
api._requests = {}
local real_request = api.request
api.request = function(endpoint, parameters, file)
    table.insert(api._requests, {
        endpoint = endpoint,
        parameters = parameters,
        file = file
    })
    -- Return a mock success response
    return { ok = true, result = true }, 200
end

-- Helper to get last request
function api._last_request()
    return api._requests[#api._requests]
end

-- Helper to clear request history
function api._clear_requests()
    api._requests = {}
end

-- Helper to mock a specific response for the next request
function api._mock_response(response)
    local original = api.request
    api.request = function(endpoint, parameters, file)
        api.request = original
        table.insert(api._requests, {
            endpoint = endpoint,
            parameters = parameters,
            file = file
        })
        return response, 200
    end
end

return api
