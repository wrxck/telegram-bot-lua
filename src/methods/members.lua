return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.ban_chat_member(chat_id, user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/banChatMember', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['until_date'] = opts.until_date,
            ['revoke_messages'] = opts.revoke_messages
        })
        return success, res
    end

    function api.unban_chat_member(chat_id, user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/unbanChatMember', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['only_if_banned'] = opts.only_if_banned
        })
        return success, res
    end

    function api.restrict_chat_member(chat_id, user_id, permissions, opts)
        opts = opts or {}
        permissions = type(permissions) == 'table' and json.encode(permissions) or permissions
        local success, res = api.request(config.endpoint .. api.token .. '/restrictChatMember', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['permissions'] = permissions,
            ['use_independent_chat_permissions'] = opts.use_independent_chat_permissions,
            ['until_date'] = opts.until_date
        })
        return success, res
    end

    function api.promote_chat_member(chat_id, user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/promoteChatMember', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['is_anonymous'] = opts.is_anonymous,
            ['can_manage_chat'] = opts.can_manage_chat,
            ['can_delete_messages'] = opts.can_delete_messages,
            ['can_manage_video_chats'] = opts.can_manage_video_chats,
            ['can_restrict_members'] = opts.can_restrict_members,
            ['can_promote_members'] = opts.can_promote_members,
            ['can_change_info'] = opts.can_change_info,
            ['can_invite_users'] = opts.can_invite_users,
            ['can_post_messages'] = opts.can_post_messages,
            ['can_edit_messages'] = opts.can_edit_messages,
            ['can_pin_messages'] = opts.can_pin_messages,
            ['can_post_stories'] = opts.can_post_stories,
            ['can_edit_stories'] = opts.can_edit_stories,
            ['can_delete_stories'] = opts.can_delete_stories,
            ['can_manage_topics'] = opts.can_manage_topics,
            ['can_manage_direct_messages'] = opts.can_manage_direct_messages
        })
        return success, res
    end

    function api.set_chat_administrator_custom_title(chat_id, user_id, custom_title)
        custom_title = tostring(custom_title)
        if custom_title:len() > 16 then
            custom_title = custom_title:sub(1, 16)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/setChatAdministratorCustomTitle', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['custom_title'] = custom_title
        })
        return success, res
    end

    function api.ban_chat_sender_chat(chat_id, sender_chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/banChatSenderChat', {
            ['chat_id'] = chat_id,
            ['sender_chat_id'] = sender_chat_id
        })
        return success, res
    end

    function api.unban_chat_sender_chat(chat_id, sender_chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unbanChatSenderChat', {
            ['chat_id'] = chat_id,
            ['sender_chat_id'] = sender_chat_id
        })
        return success, res
    end

    function api.get_user_profile_photos(user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getUserProfilePhotos', {
            ['user_id'] = user_id,
            ['offset'] = opts.offset,
            ['limit'] = opts.limit
        })
        return success, res
    end
end
