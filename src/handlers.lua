return function(api)

    -- Update handler stubs
    function api.on_update(_) end
    function api.on_message(_) end
    function api.on_private_message(_) end
    function api.on_group_message(_) end
    function api.on_supergroup_message(_) end
    function api.on_callback_query(_) end
    function api.on_inline_query(_) end
    function api.on_channel_post(_) end
    function api.on_edited_message(_) end
    function api.on_edited_private_message(_) end
    function api.on_edited_group_message(_) end
    function api.on_edited_supergroup_message(_) end
    function api.on_edited_channel_post(_) end
    function api.on_chosen_inline_result(_) end
    function api.on_shipping_query(_) end
    function api.on_pre_checkout_query(_) end
    function api.on_poll(_) end
    function api.on_poll_answer(_) end
    function api.on_message_reaction(_) end
    function api.on_message_reaction_count(_) end
    function api.on_my_chat_member(_) end
    function api.on_chat_member(_) end
    function api.on_chat_join_request(_) end
    function api.on_chat_boost(_) end
    function api.on_removed_chat_boost(_) end
    function api.on_business_connection(_) end
    function api.on_business_message(_) end
    function api.on_edited_business_message(_) end
    function api.on_deleted_business_messages(_) end
    function api.on_purchased_paid_media(_) end

    function api.process_update(update)
        if not update then
            return false
        end
        api.on_update(update)
        if update.message then
            if update.message.chat.type == 'private' then
                api.on_private_message(update.message)
            elseif update.message.chat.type == 'group' then
                api.on_group_message(update.message)
            elseif update.message.chat.type == 'supergroup' then
                api.on_supergroup_message(update.message)
            end
            return api.on_message(update.message)
        elseif update.edited_message then
            if update.edited_message.chat.type == 'private' then
                api.on_edited_private_message(update.edited_message)
            elseif update.edited_message.chat.type == 'group' then
                api.on_edited_group_message(update.edited_message)
            elseif update.edited_message.chat.type == 'supergroup' then
                api.on_edited_supergroup_message(update.edited_message)
            end
            return api.on_edited_message(update.edited_message)
        elseif update.callback_query then
            return api.on_callback_query(update.callback_query)
        elseif update.inline_query then
            return api.on_inline_query(update.inline_query)
        elseif update.channel_post then
            return api.on_channel_post(update.channel_post)
        elseif update.edited_channel_post then
            return api.on_edited_channel_post(update.edited_channel_post)
        elseif update.chosen_inline_result then
            return api.on_chosen_inline_result(update.chosen_inline_result)
        elseif update.shipping_query then
            return api.on_shipping_query(update.shipping_query)
        elseif update.pre_checkout_query then
            return api.on_pre_checkout_query(update.pre_checkout_query)
        elseif update.poll then
            return api.on_poll(update.poll)
        elseif update.poll_answer then
            return api.on_poll_answer(update.poll_answer)
        elseif update.message_reaction then
            return api.on_message_reaction(update.message_reaction)
        elseif update.message_reaction_count then
            return api.on_message_reaction_count(update.message_reaction_count)
        elseif update.my_chat_member then
            return api.on_my_chat_member(update.my_chat_member)
        elseif update.chat_member then
            return api.on_chat_member(update.chat_member)
        elseif update.chat_join_request then
            return api.on_chat_join_request(update.chat_join_request)
        elseif update.chat_boost then
            return api.on_chat_boost(update.chat_boost)
        elseif update.removed_chat_boost then
            return api.on_removed_chat_boost(update.removed_chat_boost)
        elseif update.business_connection then
            return api.on_business_connection(update.business_connection)
        elseif update.business_message then
            return api.on_business_message(update.business_message)
        elseif update.edited_business_message then
            return api.on_edited_business_message(update.edited_business_message)
        elseif update.deleted_business_messages then
            return api.on_deleted_business_messages(update.deleted_business_messages)
        elseif update.purchased_paid_media then
            return api.on_purchased_paid_media(update.purchased_paid_media)
        end
        return false
    end

    -- Async-first run loop.
    -- By default uses copas for concurrent update processing.
    -- Pass { sync = true } for single-threaded sequential processing.
    function api.run(opts)
        opts = opts or {}
        if opts.sync then
            return api._run_sync(opts)
        end
        -- Default: async via copas
        return api.async.run(opts)
    end

    -- Single-threaded synchronous polling loop (opt-in via sync = true).
    function api._run_sync(opts)
        opts = opts or {}
        local limit = tonumber(opts.limit) or 1
        local timeout = tonumber(opts.timeout) or 0
        local offset = tonumber(opts.offset) or 0
        local allowed_updates = opts.allowed_updates
        local use_beta_endpoint = opts.use_beta_endpoint
        while true do
            local updates = api.get_updates({
                timeout = timeout,
                offset = offset,
                limit = limit,
                allowed_updates = allowed_updates,
                use_beta_endpoint = use_beta_endpoint
            })
            if updates and type(updates) == 'table' and updates.result then
                for _, v in pairs(updates.result) do
                    api.process_update(v)
                    offset = v.update_id + 1
                end
            end
        end
    end
end
