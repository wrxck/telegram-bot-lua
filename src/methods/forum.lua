return function(api)
    local config = require('telegram-bot-lua.config')

    function api.get_forum_topic_icon_stickers()
        local success, res = api.request(config.endpoint .. api.token .. '/getForumTopicIconStickers')
        return success, res
    end

    function api.create_forum_topic(chat_id, name, opts)
        opts = opts or {}
        name = tostring(name)
        if name:len() > 128 then
            name = name:sub(1, 128)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/createForumTopic', {
            ['chat_id'] = chat_id,
            ['name'] = name,
            ['icon_color'] = opts.icon_color,
            ['icon_custom_emoji_id'] = opts.icon_custom_emoji_id
        })
        return success, res
    end

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

    function api.close_forum_topic(chat_id, message_thread_id)
        local success, res = api.request(config.endpoint .. api.token .. '/closeForumTopic', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id
        })
        return success, res
    end

    function api.reopen_forum_topic(chat_id, message_thread_id)
        local success, res = api.request(config.endpoint .. api.token .. '/reopenForumTopic', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id
        })
        return success, res
    end

    function api.delete_forum_topic(chat_id, message_thread_id)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteForumTopic', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id
        })
        return success, res
    end

    function api.unpin_all_forum_topic_messages(chat_id, message_thread_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unpinAllForumTopicMessages', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = message_thread_id
        })
        return success, res
    end

    function api.edit_general_forum_topic(chat_id, name)
        name = tostring(name)
        if name:len() > 128 then
            name = name:sub(1, 128)
        end
        local success, res = api.request(config.endpoint .. api.token .. '/editGeneralForumTopic', {
            ['chat_id'] = chat_id,
            ['name'] = name
        })
        return success, res
    end

    function api.close_general_forum_topic(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/closeGeneralForumTopic', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.reopen_general_forum_topic(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/reopenGeneralForumTopic', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.hide_general_forum_topic(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/hideGeneralForumTopic', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.unhide_general_forum_topic(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unhideGeneralForumTopic', {
            ['chat_id'] = chat_id
        })
        return success, res
    end

    function api.unpin_all_general_forum_topic_messages(chat_id)
        local success, res = api.request(config.endpoint .. api.token .. '/unpinAllGeneralForumTopicMessages', {
            ['chat_id'] = chat_id
        })
        return success, res
    end
end
