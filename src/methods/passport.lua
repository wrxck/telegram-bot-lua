return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.set_passport_data_errors(user_id, errors)
        errors = type(errors) == 'table' and json.encode(errors) or errors
        local success, res = api.request(config.endpoint .. api.token .. '/setPassportDataErrors', {
            ['user_id'] = user_id,
            ['errors'] = errors
        })
        return success, res
    end
end
