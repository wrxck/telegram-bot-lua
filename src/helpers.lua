--- helper methods for common telegram bot operations.
-- @module telegram-bot-lua.helpers
return function(api)

    --- get the permissions of a chat member as a normalised table.
    -- returns a table with boolean values for each permission, defaulting to false.
    -- @param chat_id number|string unique identifier for the target chat
    -- @param user_id number unique identifier of the target user
    -- @return table|boolean permissions table, or false on failure
    function api.get_chat_member_permissions(chat_id, user_id)
        if not chat_id or not user_id then
            return false
        end
        -- preserve the error detail on failure, like the other helpers do.
        local success, res = api.get_chat_member(chat_id, user_id)
        if not success then
            return success, res
        end
        local p = success.result
        return {
            ['can_be_edited'] = p.can_be_edited or false,
            ['can_manage_chat'] = p.can_manage_chat or false,
            ['can_post_messages'] = p.can_post_messages or false,
            ['can_edit_messages'] = p.can_edit_messages or false,
            ['can_delete_messages'] = p.can_delete_messages or false,
            ['can_manage_video_chats'] = p.can_manage_video_chats or false,
            ['can_restrict_members'] = p.can_restrict_members or false,
            ['can_promote_members'] = p.can_promote_members or false,
            ['can_change_info'] = p.can_change_info or false,
            ['can_invite_users'] = p.can_invite_users or false,
            ['can_pin_messages'] = p.can_pin_messages or false,
            ['can_post_stories'] = p.can_post_stories or false,
            ['can_edit_stories'] = p.can_edit_stories or false,
            ['can_delete_stories'] = p.can_delete_stories or false,
            ['can_manage_topics'] = p.can_manage_topics or false,
            ['can_manage_direct_messages'] = p.can_manage_direct_messages or false,
            ['can_send_messages'] = p.can_send_messages or false,
            ['can_send_audios'] = p.can_send_audios or false,
            ['can_send_documents'] = p.can_send_documents or false,
            ['can_send_photos'] = p.can_send_photos or false,
            ['can_send_videos'] = p.can_send_videos or false,
            ['can_send_video_notes'] = p.can_send_video_notes or false,
            ['can_send_voice_notes'] = p.can_send_voice_notes or false,
            ['can_send_polls'] = p.can_send_polls or false,
            ['can_send_other_messages'] = p.can_send_other_messages or false,
            ['can_add_web_page_previews'] = p.can_add_web_page_previews or false
        }
    end

    -- factory for the status-check helpers below: each differs only in the
    -- set of chat-member statuses it accepts.
    local function status_check(statuses)
        return function(chat_id, user_id)
            if not chat_id or not user_id then
                return false
            end
            local user, res = api.get_chat_member(chat_id, user_id)
            if not user or not user.result then
                return false, res
            elseif statuses[user.result.status] then
                return true, res
            end
            return false, user.result.status
        end
    end

    --- check if a user has been kicked (banned) from a chat.
    -- @param chat_id number|string unique identifier for the target chat
    -- @param user_id number unique identifier of the target user
    -- @return boolean true if the user is kicked
    -- @return string|number the HTTP status or the user's actual status
    api.is_user_kicked = status_check({ kicked = true })

    --- check if a user is an administrator or creator in a chat.
    -- @param chat_id number|string unique identifier for the target chat
    -- @param user_id number unique identifier of the target user
    -- @return boolean true if the user is an admin or creator
    -- @return string|number the HTTP status or the user's actual status
    api.is_user_group_admin = status_check({ administrator = true, creator = true })

    --- check if a user is the creator of a chat.
    -- @param chat_id number|string unique identifier for the target chat
    -- @param user_id number unique identifier of the target user
    -- @return boolean true if the user is the creator
    -- @return string|number the HTTP status or the user's actual status
    api.is_user_group_creator = status_check({ creator = true })

    --- check if a user is restricted in a chat.
    -- @param chat_id number|string unique identifier for the target chat
    -- @param user_id number unique identifier of the target user
    -- @return boolean true if the user is restricted
    -- @return string|number the HTTP status or the user's actual status
    api.is_user_restricted = status_check({ restricted = true })

    --- check if a user has left a chat.
    -- @param chat_id number|string unique identifier for the target chat
    -- @param user_id number unique identifier of the target user
    -- @return boolean true if the user has left
    -- @return string|number the HTTP status or the user's actual status
    api.has_user_left = status_check({ left = true })
end
