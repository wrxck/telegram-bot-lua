return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.get_updates(opts)
        opts = opts or {}
        local allowed_updates = opts.allowed_updates
        allowed_updates = type(allowed_updates) == 'table' and json.encode(allowed_updates) or allowed_updates
        local success, res = api.request(string.format('https://api.telegram.org/%sbot%s/getUpdates',
            opts.use_beta_endpoint and 'beta/' or '', api.token), {
            ['timeout'] = opts.timeout,
            ['offset'] = opts.offset,
            ['limit'] = opts.limit,
            ['allowed_updates'] = allowed_updates
        })
        return success, res
    end

    function api.set_webhook(url, opts)
        opts = opts or {}
        local allowed_updates = opts.allowed_updates
        allowed_updates = type(allowed_updates) == 'table' and json.encode(allowed_updates) or allowed_updates
        local success, res = api.request(config.endpoint .. api.token .. '/setWebhook', {
            ['url'] = url,
            ['ip_address'] = opts.ip_address,
            ['max_connections'] = opts.max_connections,
            ['allowed_updates'] = allowed_updates,
            ['drop_pending_updates'] = opts.drop_pending_updates,
            ['secret_token'] = opts.secret_token
        }, {
            ['certificate'] = opts.certificate
        })
        return success, res
    end

    function api.delete_webhook(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/deleteWebhook', {
            ['drop_pending_updates'] = opts.drop_pending_updates
        })
        return success, res
    end

    function api.get_webhook_info()
        local success, res = api.request(config.endpoint .. api.token .. '/getWebhookInfo')
        return success, res
    end
end
