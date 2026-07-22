--- chat API methods.
-- @module telegram-bot-lua.methods.chat
return function(api)
    local config = require('telegram-bot-lua.config')

    --- get up-to-date information about the chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @return table,number the response object and HTTP status
    function api.get_chat(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getChat', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- get a list of administrators in a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @param opts table optional parameters
    -- @param opts.return_bots boolean pass true to additionally receive bots that are administrators
    -- @return table,number the response object and HTTP status
    function api.get_chat_administrators(chat_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getChatAdministrators', {
            ['chat_id'] = chat_id,
            ['return_bots'] = opts.return_bots
        })
        return success, res
    end

    --- get the number of members in a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @return table,number the response object and HTTP status
    function api.get_chat_member_count(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getChatMemberCount', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- get information about a member of a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @param user_id number unique identifier of the target user
    -- @return table,number the response object and HTTP status
    function api.get_chat_member(chat_id, user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getChatMember', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        })
        return success, res
    end

    --- leave a group, supergroup or channel.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup/channel
    -- @return table,number the response object and HTTP status
    function api.leave_chat(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/leaveChat', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- change the title of a chat. truncated to 128 characters.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param title string new chat title (max 128 characters)
    -- @return table,number the response object and HTTP status
    function api.set_chat_title(chat_id, title)
        title = api._truncate(title, 128)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatTitle', {
            ['chat_id'] = chat_id,
            ['title'] = title
        })
        return success, res
    end

    --- change the description of a group, supergroup or channel. truncated to 255 characters.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param description string new chat description (max 255 characters)
    -- @return table,number the response object and HTTP status
    function api.set_chat_description(chat_id, description)
        description = api._truncate(description, 255)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatDescription', {
            ['chat_id'] = chat_id,
            ['description'] = description
        })
        return success, res
    end

    --- set a new profile photo for the chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param photo string new chat photo (file upload)
    -- @return table,number the response object and HTTP status
    function api.set_chat_photo(chat_id, photo)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatPhoto', {
            ['chat_id'] = chat_id
        }, {
            ['photo'] = photo
        })
        return success, res
    end

    --- delete a chat photo.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @return table,number the response object and HTTP status
    function api.delete_chat_photo(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteChatPhoto', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- set default chat permissions for all members.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param permissions table|string a JSON-serialized object for new default chat permissions
    -- @param opts table optional parameters
    -- @param opts.use_independent_chat_permissions boolean pass true if chat permissions are set independently
    -- @return table,number the response object and HTTP status
    function api.set_chat_permissions(chat_id, permissions, opts)
        opts = opts or {}
        permissions = api._json_enc(permissions)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatPermissions', {
            ['chat_id'] = chat_id,
            ['permissions'] = permissions,
            ['use_independent_chat_permissions'] = opts.use_independent_chat_permissions
        })
        return success, res
    end

    --- set a new group sticker set for a supergroup.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param sticker_set_name string name of the sticker set
    -- @return table,number the response object and HTTP status
    function api.set_chat_sticker_set(chat_id, sticker_set_name)
        local success, res = api.request(config.endpoint .. api.token .. '/setChatStickerSet', {
            ['chat_id'] = chat_id,
            ['sticker_set_name'] = sticker_set_name
        })
        return success, res
    end

    --- delete a group sticker set from a supergroup.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @return table,number the response object and HTTP status
    function api.delete_chat_sticker_set(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteChatStickerSet', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- pin a message in a group, supergroup or channel.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param message_id number identifier of a message to pin
    -- @param opts table optional parameters
    -- @param opts.disable_notification boolean pass true to pin silently
    -- @param opts.business_connection_id string unique identifier of the business connection
    -- @return table,number the response object and HTTP status
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

    --- remove a message from the list of pinned messages in a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param opts table optional parameters
    -- @param opts.message_id number identifier of the message to unpin
    -- @param opts.business_connection_id string unique identifier of the business connection
    -- @return table,number the response object and HTTP status
    function api.unpin_chat_message(chat_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/unpinChatMessage', {
            ['chat_id'] = chat_id,
            ['message_id'] = opts.message_id,
            ['business_connection_id'] = opts.business_connection_id
        })
        return success, res
    end

    --- clear the list of pinned messages in a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @return table,number the response object and HTTP status
    function api.unpin_all_chat_messages(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unpinAllChatMessages', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- generate a new primary invite link for a chat; any previously generated primary link is revoked.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @return table,number the response object and HTTP status
    function api.export_chat_invite_link(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/exportChatInviteLink', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- create an additional invite link for a chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param opts table optional parameters
    -- @param opts.name string invite link name (max 32 characters)
    -- @param opts.expire_date number point in time (unix timestamp) when the link will expire
    -- @param opts.member_limit number maximum number of users that can be members simultaneously
    -- @param opts.creates_join_request boolean true if users joining via the link need to be approved
    -- @return table,number the response object and HTTP status
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

    --- edit a non-primary invite link created by the bot.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param invite_link string the invite link to edit
    -- @param opts table optional parameters
    -- @param opts.name string invite link name (max 32 characters)
    -- @param opts.expire_date number point in time (unix timestamp) when the link will expire
    -- @param opts.member_limit number maximum number of users that can be members simultaneously
    -- @param opts.creates_join_request boolean true if users joining via the link need to be approved
    -- @return table,number the response object and HTTP status
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

    --- revoke an invite link created by the bot.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param invite_link string the invite link to revoke
    -- @return table,number the response object and HTTP status
    function api.revoke_chat_invite_link(chat_id, invite_link)
        local success, res = api.request(config.endpoint .. api.token .. '/revokeChatInviteLink', {
            ['chat_id'] = chat_id,
            ['invite_link'] = invite_link
        })
        return success, res
    end

    --- approve a chat join request.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param user_id number unique identifier of the target user
    -- @return table,number the response object and HTTP status
    function api.approve_chat_join_request(chat_id, user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/approveChatJoinRequest', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        })
        return success, res
    end

    --- decline a chat join request.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param user_id number unique identifier of the target user
    -- @return table,number the response object and HTTP status
    function api.decline_chat_join_request(chat_id, user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/declineChatJoinRequest', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        })
        return success, res
    end

    --- get the list of boosts added to a chat by a user.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param user_id number unique identifier of the target user
    -- @return table,number the response object and HTTP status
    function api.get_user_chat_boosts(chat_id, user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getUserChatBoosts', {
            ['chat_id'] = chat_id,
            ['user_id'] = user_id
        })
        return success, res
    end

    --- answer a join request query received from a guard bot (Bot API 10.1).
    -- @param chat_join_request_query_id string unique identifier of the join request query
    -- @param result string one of "approve", "decline", or "queue"
    -- @return table,number the response object and HTTP status
    function api.answer_chat_join_request_query(chat_join_request_query_id, result)
        local success, res = api.request(config.endpoint .. api.token .. '/answerChatJoinRequestQuery', {
            ['chat_join_request_query_id'] = chat_join_request_query_id,
            ['result'] = result
        })
        return success, res
    end

    --- open a mini app in response to a join request query (Bot API 10.1).
    -- @param chat_join_request_query_id string unique identifier of the join request query
    -- @param web_app_url string the url of the mini app to be opened
    -- @return table,number the response object and HTTP status
    function api.send_chat_join_request_web_app(chat_join_request_query_id, web_app_url)
        local success, res = api.request(config.endpoint .. api.token .. '/sendChatJoinRequestWebApp', {
            ['chat_join_request_query_id'] = chat_join_request_query_id,
            ['web_app_url'] = web_app_url
        })
        return success, res
    end

    --- create a subscription invite link for a channel chat.
    -- @param chat_id number|string unique identifier for the target channel chat or username of the target channel
    -- @param subscription_period number the number of seconds the subscription will be active before the next payment
    -- @param subscription_price number the amount of telegram stars a user must pay to be a member of the chat; 1-10000
    -- @param opts table optional parameters
    -- @param opts.name string invite link name (max 32 characters)
    -- @return table,number the response object and HTTP status
    function api.create_chat_subscription_invite_link(chat_id, subscription_period, subscription_price, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/createChatSubscriptionInviteLink', {
            ['chat_id'] = chat_id,
            ['name'] = opts.name,
            ['subscription_period'] = subscription_period,
            ['subscription_price'] = subscription_price
        })
        return success, res
    end

    --- edit a subscription invite link created by the bot.
    -- @param chat_id number|string unique identifier for the target chat or username of the target channel
    -- @param invite_link string the invite link to edit
    -- @param opts table optional parameters
    -- @param opts.name string invite link name (max 32 characters)
    -- @return table,number the response object and HTTP status
    function api.edit_chat_subscription_invite_link(chat_id, invite_link, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/editChatSubscriptionInviteLink', {
            ['chat_id'] = chat_id,
            ['invite_link'] = invite_link,
            ['name'] = opts.name
        })
        return success, res
    end
end
