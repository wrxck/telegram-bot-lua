--- rich message API methods (Bot API 10.1).
-- @module telegram-bot-lua.methods.rich
return function(api)
    local config = require('telegram-bot-lua.config')

    --- send a rich formatted message to a chat.
    -- a rich message is described with HTML or markdown via an InputRichMessage object;
    -- see api.input_rich_message for a builder.
    -- @param chat_id number|string unique identifier for the target chat or username of the target bot/supergroup/channel
    -- @param rich_message table|string an InputRichMessage object describing the message to send
    -- @param opts table optional parameters
    -- @param opts.business_connection_id string unique identifier of the business connection
    -- @param opts.message_thread_id number unique identifier for the target message thread (topic) of a forum
    -- @param opts.direct_messages_topic_id number identifier of the direct messages topic to send to
    -- @param opts.disable_notification boolean send the message silently
    -- @param opts.protect_content boolean protect the contents of the sent message from forwarding and saving
    -- @param opts.allow_paid_broadcast boolean allow up to 1000 messages per second for a fee
    -- @param opts.message_effect_id string unique identifier of the message effect to add; private chats only
    -- @param opts.suggested_post_parameters table parameters of the suggested post to send
    -- @param opts.reply_parameters table description of the message to reply to
    -- @param opts.reply_markup table additional interface options
    -- @return table,number the response object and HTTP status
    function api.send_rich_message(chat_id, rich_message, opts)
        opts = opts or {}
        rich_message = api._json_enc(rich_message)
        local suggested_post_parameters = opts.suggested_post_parameters
        suggested_post_parameters = api._json_enc(suggested_post_parameters)
        local reply_parameters = opts.reply_parameters
        reply_parameters = api._json_enc(reply_parameters)
        local reply_markup = opts.reply_markup
        reply_markup = api._json_enc(reply_markup)
        local success, res = api.request(config.endpoint .. api.token .. '/sendRichMessage', {
            ['business_connection_id'] = opts.business_connection_id,
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['rich_message'] = rich_message,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast,
            ['message_effect_id'] = opts.message_effect_id,
            ['suggested_post_parameters'] = suggested_post_parameters,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup
        })
        return success, res
    end

    --- stream a partial rich message to a private chat as a draft.
    -- repeated calls with the same draft_id animate the changes; useful for streaming
    -- AI-generated replies. a non-zero draft_id is required.
    -- @param chat_id number unique identifier for the target private chat
    -- @param draft_id number unique identifier of the message draft; must be non-zero
    -- @param rich_message table|string an InputRichMessage object describing the partial message
    -- @param opts table optional parameters
    -- @param opts.message_thread_id number unique identifier for the target message thread
    -- @return table,number the response object and HTTP status
    function api.send_rich_message_draft(chat_id, draft_id, rich_message, opts)
        opts = opts or {}
        rich_message = api._json_enc(rich_message)
        local success, res = api.request(config.endpoint .. api.token .. '/sendRichMessageDraft', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['draft_id'] = draft_id,
            ['rich_message'] = rich_message
        })
        return success, res
    end
end
