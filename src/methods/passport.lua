--- passport API methods.
-- @module telegram-bot-lua.methods.passport
return function(api)
    local config = require('telegram-bot-lua.config')

    --- inform a user that some of the telegram passport elements they provided contain errors.
    -- @param user_id number identifier of the user
    -- @param errors string|table JSON-serialised array of PassportElementError or a table thereof
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.set_passport_data_errors(user_id, errors)
        errors = api._json_enc(errors)
        local success, res = api.request(config.endpoint .. api.token .. '/setPassportDataErrors', {
            ['user_id'] = user_id,
            ['errors'] = errors
        })
        return success, res
    end
end
