return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.get_file(file_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getFile', {
            ['file_id'] = file_id
        })
        return success, res
    end

    function api.set_my_commands(commands, opts)
        opts = opts or {}
        commands = type(commands) == 'table' and json.encode(commands) or commands
        local scope = opts.scope
        scope = type(scope) == 'table' and json.encode(scope) or scope
        local success, res = api.request(config.endpoint .. api.token .. '/setMyCommands', {
            ['commands'] = commands,
            ['scope'] = scope,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.delete_my_commands(opts)
        opts = opts or {}
        local scope = opts.scope
        scope = type(scope) == 'table' and json.encode(scope) or scope
        local success, res = api.request(config.endpoint .. api.token .. '/deleteMyCommands', {
            ['scope'] = scope,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.get_my_commands(opts)
        opts = opts or {}
        local scope = opts.scope
        scope = type(scope) == 'table' and json.encode(scope) or scope
        local success, res = api.request(config.endpoint .. api.token .. '/getMyCommands', {
            ['scope'] = scope,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.set_my_name(name, opts)
        opts = opts or {}
        name = tostring(name)
        if name:len() > 64 then
            name = name:sub(1, 64)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/setMyName', {
            ['name'] = name,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.get_my_name(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getMyName', {
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.set_my_description(description, opts)
        opts = opts or {}
        description = tostring(description)
        if description:len() > 512 then
            description = description:sub(1, 512)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/setMyDescription', {
            ['description'] = description,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.get_my_description(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getMyDescription', {
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.set_my_short_description(short_description, opts)
        opts = opts or {}
        short_description = tostring(short_description)
        if short_description:len() > 120 then
            short_description = short_description:sub(1, 120)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/setMyShortDescription', {
            ['short_description'] = short_description,
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.get_my_short_description(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getMyShortDescription', {
            ['language_code'] = opts.language_code
        })
        return success, res
    end

    function api.set_chat_menu_button(opts)
        opts = opts or {}
        local menu_button = opts.menu_button
        menu_button = type(menu_button) == 'table' and json.encode(menu_button) or menu_button
        local success, res = api.request(config.endpoint .. api.token .. '/setChatMenuButton', {
            ['chat_id'] = opts.chat_id,
            ['menu_button'] = menu_button
        })
        return success, res
    end

    function api.get_chat_menu_button(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getChatMenuButton', {
            ['chat_id'] = opts.chat_id
        })
        return success, res
    end

    function api.set_my_default_administrator_rights(opts)
        opts = opts or {}
        local rights = opts.rights
        rights = type(rights) == 'table' and json.encode(rights) or rights
        local success, res = api.request(config.endpoint .. api.token .. '/setMyDefaultAdministratorRights', {
            ['rights'] = rights,
            ['for_channels'] = opts.for_channels
        })
        return success, res
    end

    function api.get_my_default_administrator_rights(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getMyDefaultAdministratorRights', {
            ['for_channels'] = opts.for_channels
        })
        return success, res
    end

    function api.set_my_profile_photo(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setMyProfilePhoto', {
            ['is_public'] = opts.is_public
        }, {
            ['photo'] = opts.photo
        })
        return success, res
    end

    function api.remove_my_profile_photo(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/removeMyProfilePhoto', {
            ['is_public'] = opts.is_public
        })
        return success, res
    end
end
