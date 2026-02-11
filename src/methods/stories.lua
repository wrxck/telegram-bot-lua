return function(api)
    local config = require('telegram-bot-lua.config')

    function api.repost_story(chat_id, story_id)
        local success, res = api.request(config.endpoint .. api.token .. '/repostStory', {
            ['chat_id'] = chat_id,
            ['story_id'] = story_id
        })
        return success, res
    end
end
