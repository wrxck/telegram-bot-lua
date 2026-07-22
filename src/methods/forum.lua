--- forum API methods.
-- @module telegram-bot-lua.methods.forum
return function(api)
    local config = require('telegram-bot-lua.config')

    --- get custom emoji stickers which can be used as a forum topic icon.
    -- @return table,number the response object and HTTP status
    function api.get_forum_topic_icon_stickers()
        local success, res = api.request(config.endpoint .. api.token .. '/getForumTopicIconStickers')
        return success, res
    end

    --- create a topic in a forum supergroup chat. name is truncated to 128 characters.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param name string topic name (max 128 characters)
    -- @param opts table optional parameters
    -- @param opts.icon_color number colour of the topic icon in RGB format
    -- @param opts.icon_custom_emoji_id string unique identifier of the custom emoji shown as the topic icon
    -- @return table,number the response object and HTTP status
    function api.create_forum_topic(chat_id, name, opts)
        opts = opts or {}
        name = api._truncate(name, 128)
        local success, res = api.request(config.endpoint .. api.token .. '/createForumTopic', {
            ['chat_id'] = chat_id,
            ['name'] = name,
            ['icon_color'] = opts.icon_color,
            ['icon_custom_emoji_id'] = opts.icon_custom_emoji_id
        })
        return success, res
    end

    --- edit name and icon of a topic in a forum supergroup chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param message_thread_id number unique identifier for the target message thread of the forum topic
    -- @param opts table optional parameters
    -- @param opts.name string new topic name (max 128 characters)
    -- @param opts.icon_custom_emoji_id string new unique identifier of the custom emoji shown as the topic icon
    -- @return table,number the response object and HTTP status
    function api.edit_forum_topic(chat_id, message_thread_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/editForumTopic', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id,
            ['name'] = opts.name,
            ['icon_custom_emoji_id'] = opts.icon_custom_emoji_id
        })
        return success, res
    end

    --- close an open topic in a forum supergroup chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param message_thread_id number unique identifier for the target message thread of the forum topic
    -- @return table,number the response object and HTTP status
    function api.close_forum_topic(chat_id, message_thread_id)
        local success, res = api.request(config.endpoint .. api.token .. '/closeForumTopic', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id
        })
        return success, res
    end

    --- reopen a closed topic in a forum supergroup chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param message_thread_id number unique identifier for the target message thread of the forum topic
    -- @return table,number the response object and HTTP status
    function api.reopen_forum_topic(chat_id, message_thread_id)
        local success, res = api.request(config.endpoint .. api.token .. '/reopenForumTopic', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id
        })
        return success, res
    end

    --- delete a forum topic along with all its messages in a forum supergroup chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param message_thread_id number unique identifier for the target message thread of the forum topic
    -- @return table,number the response object and HTTP status
    function api.delete_forum_topic(chat_id, message_thread_id)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteForumTopic', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id
        })
        return success, res
    end

    --- clear the list of pinned messages in a forum topic.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param message_thread_id number unique identifier for the target message thread of the forum topic
    -- @return table,number the response object and HTTP status
    function api.unpin_all_forum_topic_messages(chat_id, message_thread_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unpinAllForumTopicMessages', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id
        })
        return success, res
    end

    --- edit the name of the 'General' topic in a forum supergroup chat. name is truncated to 128 characters.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @param name string new topic name (max 128 characters)
    -- @return table,number the response object and HTTP status
    function api.edit_general_forum_topic(chat_id, name)
        name = api._truncate(name, 128)
        local success, res = api.request(config.endpoint .. api.token .. '/editGeneralForumTopic', {
            ['chat_id'] = chat_id,
            ['name'] = name
        })
        return success, res
    end

    --- close an open 'General' topic in a forum supergroup chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @return table,number the response object and HTTP status
    function api.close_general_forum_topic(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/closeGeneralForumTopic', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- reopen a closed 'General' topic in a forum supergroup chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @return table,number the response object and HTTP status
    function api.reopen_general_forum_topic(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/reopenGeneralForumTopic', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- hide the 'General' topic in a forum supergroup chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @return table,number the response object and HTTP status
    function api.hide_general_forum_topic(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/hideGeneralForumTopic', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- unhide the 'General' topic in a forum supergroup chat.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @return table,number the response object and HTTP status
    function api.unhide_general_forum_topic(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unhideGeneralForumTopic', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    --- clear the list of pinned messages in the general forum topic.
    -- @param chat_id number|string unique identifier for the target chat or username of the target supergroup
    -- @return table,number the response object and HTTP status
    function api.unpin_all_general_forum_topic_messages(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unpinAllGeneralForumTopicMessages', {
            ['chat_id'] = chat_id
        })
        return success, res
    end
end
