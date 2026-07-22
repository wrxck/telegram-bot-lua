--- updates API methods.
-- @module telegram-bot-lua.methods.updates
return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    --- receive incoming updates using long polling.
    -- @param opts table optional parameters (timeout, offset, limit, allowed_updates, use_beta_endpoint)
    -- @return table|false the list of update objects, or false on failure
    -- @return string|table the HTTP status or error details
    function api.get_updates(opts)
        opts = opts or {}
        local allowed_updates = opts.allowed_updates
        allowed_updates = type(allowed_updates) == 'table' and json.encode(allowed_updates) or allowed_updates
        -- honour config.endpoint like every other method (it can point at a
        -- local bot API server); the beta endpoint inserts 'beta/' before the
        -- trailing 'bot' path segment.
        local endpoint = config.endpoint
        if opts.use_beta_endpoint then
            endpoint = endpoint:gsub('bot$', 'beta/bot', 1)
        end
        local success, res = api.request(endpoint .. api.token .. '/getUpdates', {
            ['timeout'] = opts.timeout,
            ['offset'] = opts.offset,
            ['limit'] = opts.limit,
            ['allowed_updates'] = allowed_updates
        })
        return success, res
    end

    --- set a webhook URL to receive incoming updates.
    -- @param url string the HTTPS URL to send updates to
    -- @param opts table optional parameters (certificate, ip_address, max_connections, allowed_updates, drop_pending_updates, secret_token)
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
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

    --- remove the current webhook integration.
    -- @param opts table optional parameters (drop_pending_updates)
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.delete_webhook(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/deleteWebhook', {
            ['drop_pending_updates'] = opts.drop_pending_updates
        })
        return success, res
    end

    --- get current webhook status and configuration.
    -- @return table|false the webhook info object, or false on failure
    -- @return string|table the HTTP status or error details
    function api.get_webhook_info()
        local success, res = api.request(config.endpoint .. api.token .. '/getWebhookInfo')
        return success, res
    end
end
