return function(api)
    local config = require('telegram-bot-lua.config')

    function api.get_user_gifts(user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getUserGifts', {
            ['user_id'] = user_id
        })
        return success, res
    end

    function api.get_available_gifts()
        local success, res = api.request(config.endpoint .. api.token .. '/getAvailableGifts')
        return success, res
    end

    function api.send_gift(user_id, gift_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/sendGift', {
            ['user_id'] = user_id,
            ['gift_id'] = gift_id,
            ['text'] = opts.text,
            ['text_parse_mode'] = opts.text_parse_mode,
            ['pay_for_upgrade'] = opts.pay_for_upgrade
        })
        return success, res
    end
end
