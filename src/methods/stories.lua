--- stories API methods.
-- @module telegram-bot-lua.methods.stories
return function(api)
    local config = require('telegram-bot-lua.config')

    --- repost a story to a chat.
    -- @param chat_id string|number unique identifier for the target chat
    -- @param story_id number unique identifier of the story to repost
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.repost_story(chat_id, story_id)
        local success, res = api.request(config.endpoint .. api.token .. '/repostStory', {
            ['chat_id'] = chat_id,
            ['story_id'] = story_id
        })
        return success, res
    end

    --- post a story on behalf of a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param content table|string a JSON-serialized InputStoryContent describing the story content
    -- @param active_period number period after which the story is moved to the archive, in seconds
    -- @param opts table optional parameters
    -- @param opts.caption string caption of the story; 0-2048 characters after entities parsing
    -- @param opts.parse_mode string mode for parsing entities in the story caption
    -- @param opts.caption_entities table|string a JSON-serialized list of special entities in the caption
    -- @param opts.areas table|string a JSON-serialized list of clickable areas to be shown on the story
    -- @param opts.post_to_chat_page boolean pass true to keep the story accessible after it expires
    -- @param opts.protect_content boolean pass true to protect the story from forwarding and screenshotting
    -- @return table|false the posted story, or false on failure
    -- @return string|table the HTTP status or error details
    function api.post_story(business_connection_id, content, active_period, opts)
        opts = opts or {}
        content = api._json_enc(content)
        local caption_entities = opts.caption_entities
        caption_entities = api._json_enc(caption_entities)
        local areas = opts.areas
        areas = api._json_enc(areas)
        local success, res = api.request(config.endpoint .. api.token .. '/postStory', {
            ['business_connection_id'] = business_connection_id,
            ['content'] = content,
            ['active_period'] = active_period,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['areas'] = areas,
            ['post_to_chat_page'] = opts.post_to_chat_page,
            ['protect_content'] = opts.protect_content
        })
        return success, res
    end

    --- edit a story previously posted by the bot on behalf of a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param story_id number unique identifier of the story to edit
    -- @param content table|string a JSON-serialized InputStoryContent describing the story content
    -- @param opts table optional parameters
    -- @param opts.caption string caption of the story; 0-2048 characters after entities parsing
    -- @param opts.parse_mode string mode for parsing entities in the story caption
    -- @param opts.caption_entities table|string a JSON-serialized list of special entities in the caption
    -- @param opts.areas table|string a JSON-serialized list of clickable areas to be shown on the story
    -- @return table|false the edited story, or false on failure
    -- @return string|table the HTTP status or error details
    function api.edit_story(business_connection_id, story_id, content, opts)
        opts = opts or {}
        content = api._json_enc(content)
        local caption_entities = opts.caption_entities
        caption_entities = api._json_enc(caption_entities)
        local areas = opts.areas
        areas = api._json_enc(areas)
        local success, res = api.request(config.endpoint .. api.token .. '/editStory', {
            ['business_connection_id'] = business_connection_id,
            ['story_id'] = story_id,
            ['content'] = content,
            ['caption'] = opts.caption,
            ['parse_mode'] = opts.parse_mode,
            ['caption_entities'] = caption_entities,
            ['areas'] = areas
        })
        return success, res
    end

    --- delete a story previously posted by the bot on behalf of a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param story_id number unique identifier of the story to delete
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.delete_story(business_connection_id, story_id)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteStory', {
            ['business_connection_id'] = business_connection_id,
            ['story_id'] = story_id
        })
        return success, res
    end
end
