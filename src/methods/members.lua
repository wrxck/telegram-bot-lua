--- members API methods.
-- @module telegram-bot-lua.methods.members
return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    --- ban a user from a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @param user_id number unique identifier of the target user
    -- @param opts table optional parameters
    -- @param opts.until_date number date when the user will be unbanned (unix timestamp)
    -- @param opts.revoke_messages boolean pass true to delete all messages from the chat for the user
    -- @return table,number the response object and HTTP status
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

    --- unban a previously banned user in a supergroup or channel.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @param user_id number unique identifier of the target user
    -- @param opts table optional parameters
    -- @param opts.only_if_banned boolean do nothing if the user is not banned
    -- @return table,number the response object and HTTP status
    function api.unban_chat_member(chat_id, user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/unbanChatMember', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['only_if_banned'] = opts.only_if_banned
        })
        return success, res
    end

    --- restrict a user in a supergroup.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param user_id number unique identifier of the target user
    -- @param permissions table|string a JSON-serialized object for new user permissions
    -- @param opts table optional parameters
    -- @param opts.use_independent_chat_permissions boolean pass true if chat permissions are set independently
    -- @param opts.until_date number date when restrictions will be lifted (unix timestamp)
    -- @return table,number the response object and HTTP status
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

    --- promote or demote a user in a supergroup or channel.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @param user_id number unique identifier of the target user
    -- @param opts table optional parameters
    -- @param opts.is_anonymous boolean pass true if the administrator's presence in the chat is hidden
    -- @param opts.can_manage_chat boolean pass true if the administrator can manage the chat
    -- @param opts.can_delete_messages boolean pass true if the administrator can delete messages
    -- @param opts.can_restrict_members boolean pass true if the administrator can restrict members
    -- @param opts.can_promote_members boolean pass true if the administrator can promote members
    -- @return table,number the response object and HTTP status
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
            ['can_manage_direct_messages'] = opts.can_manage_direct_messages,
            ['can_manage_tags'] = opts.can_manage_tags
        })
        return success, res
    end

    --- set a custom title for an administrator in a supergroup promoted by the bot. truncated to 16 characters.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param user_id number unique identifier of the target user
    -- @param custom_title string new custom title for the administrator (max 16 characters)
    -- @return table,number the response object and HTTP status
    function api.set_chat_administrator_custom_title(chat_id, user_id, custom_title)
        custom_title = api._truncate(custom_title, 16)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatAdministratorCustomTitle', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['custom_title'] = custom_title
        })
        return success, res
    end

    --- ban a channel chat in a supergroup or channel.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @param sender_chat_id number unique identifier of the target sender chat
    -- @return table,number the response object and HTTP status
    function api.ban_chat_sender_chat(chat_id, sender_chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/banChatSenderChat', {
            ['chat_id'] = chat_id,
            ['sender_chat_id'] = sender_chat_id
        })
        return success, res
    end

    --- unban a previously banned channel chat in a supergroup or channel.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @param sender_chat_id number unique identifier of the target sender chat
    -- @return table,number the response object and HTTP status
    function api.unban_chat_sender_chat(chat_id, sender_chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unbanChatSenderChat', {
            ['chat_id'] = chat_id,
            ['sender_chat_id'] = sender_chat_id
        })
        return success, res
    end

    --- set the tag of a chat member.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param user_id number unique identifier of the target user
    -- @param opts table optional parameters
    -- @param opts.tag string the tag to assign to the member
    -- @return table,number the response object and HTTP status
    function api.set_chat_member_tag(chat_id, user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setChatMemberTag', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id,
            ['tag'] = opts.tag
        })
        return success, res
    end

    --- get a list of profile pictures for a user.
    -- @param user_id number unique identifier of the target user
    -- @param opts table optional parameters
    -- @param opts.offset number sequential number of the first photo to be returned
    -- @param opts.limit number limits the number of photos to be retrieved (1-100)
    -- @return table,number the response object and HTTP status
    function api.get_user_profile_photos(user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getUserProfilePhotos', {
            ['user_id'] = user_id,
            ['offset'] = opts.offset,
            ['limit'] = opts.limit
        })
        return success, res
    end

    --- get a list of profile audios for a user.
    -- @param user_id number unique identifier of the target user
    -- @param opts table optional parameters
    -- @param opts.offset number sequential number of the first audio to be returned
    -- @param opts.limit number limits the number of audios to be retrieved
    -- @return table,number the response object and HTTP status
    function api.get_user_profile_audios(user_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getUserProfileAudios', {
            ['user_id'] = user_id,
            ['offset'] = opts.offset,
            ['limit'] = opts.limit
        })
        return success, res
    end
end
