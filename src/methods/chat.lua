return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.get_chat(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getChat', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.get_chat_administrators(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getChatAdministrators', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.get_chat_member_count(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getChatMemberCount', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.get_chat_member(chat_id, user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getChatMember', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        })
        return success, res
    end

    function api.leave_chat(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/leaveChat', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.set_chat_title(chat_id, title)
        title = tostring(title)
        if title:len() > 128 then
            title = title:sub(1, 128)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/setChatTitle', {
            ['chat_id'] = chat_id,
            ['title'] = title
        })
        return success, res
    end

    function api.set_chat_description(chat_id, description)
        description = tostring(description)
        if description:len() > 255 then
            description = description:sub(1, 255)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/setChatDescription', {
            ['chat_id'] = chat_id,
            ['description'] = description
        })
        return success, res
    end

    function api.set_chat_photo(chat_id, photo)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatPhoto', {
            ['chat_id'] = chat_id
        }, {
            ['photo'] = photo
        })
        return success, res
    end

    function api.delete_chat_photo(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteChatPhoto', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.set_chat_permissions(chat_id, permissions, opts)
        opts = opts or {}
        permissions = type(permissions) == 'table' and json.encode(permissions) or permissions
        local success, res = api.request(config.endpoint .. api.token .. '/setChatPermissions', {
            ['chat_id'] = chat_id,
            ['permissions'] = permissions,
            ['use_independent_chat_permissions'] = opts.use_independent_chat_permissions
        })
        return success, res
    end

    function api.set_chat_sticker_set(chat_id, sticker_set_name)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatStickerSet', {
            ['chat_id'] = chat_id,
            ['sticker_set_name'] = sticker_set_name
        })
        return success, res
    end

    function api.delete_chat_sticker_set(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteChatStickerSet', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.pin_chat_message(chat_id, message_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/pinChatMessage', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['disable_notification'] = opts.disable_notification,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.unpin_chat_message(chat_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/unpinChatMessage', {
            ['chat_id'] = chat_id,
            ['message_id'] = opts.message_id,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    function api.unpin_all_chat_messages(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unpinAllChatMessages', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.export_chat_invite_link(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/exportChatInviteLink', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.create_chat_invite_link(chat_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/createChatInviteLink', {
            ['chat_id'] = chat_id,
            ['name'] = opts.name,
            ['expire_date'] = opts.expire_date,
            ['member_limit'] = opts.member_limit,
            ['creates_join_request'] = opts.creates_join_request
        })
        return success, res
    end

    function api.edit_chat_invite_link(chat_id, invite_link, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/editChatInviteLink', {
            ['chat_id'] = chat_id,
            ['invite_link'] = invite_link,
            ['name'] = opts.name,
            ['expire_date'] = opts.expire_date,
            ['member_limit'] = opts.member_limit,
            ['creates_join_request'] = opts.creates_join_request
        })
        return success, res
    end

    function api.revoke_chat_invite_link(chat_id, invite_link)
        local success, res = api.request(config.endpoint .. api.token .. '/revokeChatInviteLink', {
            ['chat_id'] = chat_id,
            ['invite_link'] = invite_link
        })
        return success, res
    end

    function api.approve_chat_join_request(chat_id, user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/approveChatJoinRequest', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        })
        return success, res
    end

    function api.decline_chat_join_request(chat_id, user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/declineChatJoinRequest', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        })
        return success, res
    end

    function api.get_user_chat_boosts(chat_id, user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getUserChatBoosts', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        })
        return success, res
    end
end
