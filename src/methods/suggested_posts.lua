return function(api)
    local config = require('telegram-bot-lua.config')

    function api.approve_suggested_post(suggested_post_id)
        local success, res = api.request(config.endpoint .. api.token .. '/approveSuggestedPost', {
            ['suggested_post_id'] = suggested_post_id
        })
        return success, res
    end

    function api.decline_suggested_post(suggested_post_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/declineSuggestedPost', {
            ['suggested_post_id'] = suggested_post_id,
            ['reason'] = opts.reason
        })
        return success, res
    end
end
