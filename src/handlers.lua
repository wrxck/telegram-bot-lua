--- update handler stubs and dispatch logic.
-- @module telegram-bot-lua.handlers
return function(api)

    -- canonical ordered list of update payload fields, in dispatch priority
    -- order. shared by the dispatcher below, the middleware context builder
    -- and the framework context builder so every layer agrees on which
    -- update types exist.
    api._update_types = {
        'message', 'edited_message', 'callback_query', 'inline_query',
        'channel_post', 'edited_channel_post', 'chosen_inline_result',
        'shipping_query', 'pre_checkout_query', 'poll', 'poll_answer',
        'message_reaction', 'message_reaction_count', 'my_chat_member',
        'chat_member', 'chat_join_request', 'chat_boost', 'removed_chat_boost',
        'business_connection', 'business_message', 'edited_business_message',
        'deleted_business_messages', 'purchased_paid_media', 'managed_bot',
        'guest_message'
    }

    --- @section update handler stubs
    -- override these functions to handle specific update types.
    -- each receives the relevant update object as its only argument.

    --- called for every update received, before type-specific routing.
    -- @param update table the raw update object
    function api.on_update(_) end
    --- called for any new message (after chat-type-specific handlers).
    -- @param message table the message object
    function api.on_message(_) end
    --- called for new messages in private chats.
    -- @param message table the message object
    function api.on_private_message(_) end
    --- called for new messages in group chats.
    -- @param message table the message object
    function api.on_group_message(_) end
    --- called for new messages in supergroup chats.
    -- @param message table the message object
    function api.on_supergroup_message(_) end
    --- called when a callback query is received from an inline keyboard button.
    -- @param callback_query table the callback query object
    function api.on_callback_query(_) end
    --- called when an inline query is received.
    -- @param inline_query table the inline query object
    function api.on_inline_query(_) end
    --- called for new posts in channels.
    -- @param channel_post table the channel post message object
    function api.on_channel_post(_) end
    --- called when a message is edited.
    -- @param edited_message table the edited message object
    function api.on_edited_message(_) end
    --- called when a message is edited in a private chat.
    -- @param edited_message table the edited message object
    function api.on_edited_private_message(_) end
    --- called when a message is edited in a group chat.
    -- @param edited_message table the edited message object
    function api.on_edited_group_message(_) end
    --- called when a message is edited in a supergroup chat.
    -- @param edited_message table the edited message object
    function api.on_edited_supergroup_message(_) end
    --- called when a channel post is edited.
    -- @param edited_channel_post table the edited channel post object
    function api.on_edited_channel_post(_) end
    --- called when a chosen inline result is received.
    -- @param chosen_inline_result table the chosen inline result object
    function api.on_chosen_inline_result(_) end
    --- called when a shipping query is received (payments).
    -- @param shipping_query table the shipping query object
    function api.on_shipping_query(_) end
    --- called when a pre-checkout query is received (payments).
    -- @param pre_checkout_query table the pre-checkout query object
    function api.on_pre_checkout_query(_) end
    --- called when a poll state changes.
    -- @param poll table the poll object with current state
    function api.on_poll(_) end
    --- called when a user changes their vote in a non-anonymous poll.
    -- @param poll_answer table the poll answer object
    function api.on_poll_answer(_) end
    --- called when a message reaction is changed by a user.
    -- @param message_reaction table the message reaction updated object
    function api.on_message_reaction(_) end
    --- called when anonymous reactions on a message are changed.
    -- @param message_reaction_count table the reaction count updated object
    function api.on_message_reaction_count(_) end
    --- called when the bot's own chat member status is updated.
    -- @param my_chat_member table the chat member updated object
    function api.on_my_chat_member(_) end
    --- called when a chat member's status is updated.
    -- @param chat_member table the chat member updated object
    function api.on_chat_member(_) end
    --- called when a user sends a join request to a chat.
    -- @param chat_join_request table the chat join request object
    function api.on_chat_join_request(_) end
    --- called when a chat boost is added.
    -- @param chat_boost table the chat boost updated object
    function api.on_chat_boost(_) end
    --- called when a chat boost is removed.
    -- @param removed_chat_boost table the chat boost removed object
    function api.on_removed_chat_boost(_) end
    --- called when a business connection is updated.
    -- @param business_connection table the business connection object
    function api.on_business_connection(_) end
    --- called for new messages from a connected business account.
    -- @param business_message table the business message object
    function api.on_business_message(_) end
    --- called when a business message is edited.
    -- @param edited_business_message table the edited business message object
    function api.on_edited_business_message(_) end
    --- called when business messages are deleted.
    -- @param deleted_business_messages table the deleted messages object
    function api.on_deleted_business_messages(_) end
    --- called when paid media is purchased.
    -- @param purchased_paid_media table the purchased paid media object
    function api.on_purchased_paid_media(_) end
    --- called when a managed bot update is received.
    -- @param managed_bot table the managed bot updated object
    function api.on_managed_bot(_) end
    --- called when the bot receives a guest message (Bot API 10.0).
    -- @param guest_message table the guest message update object
    function api.on_guest_message(_) end

    -- chat-type-specific handlers invoked before the general handler for
    -- message-like updates.
    local chat_scoped_handlers = {
        message = {
            private = 'on_private_message',
            group = 'on_group_message',
            supergroup = 'on_supergroup_message'
        },
        edited_message = {
            private = 'on_edited_private_message',
            group = 'on_edited_group_message',
            supergroup = 'on_edited_supergroup_message'
        }
    }

    --- raw dispatch: routes an update directly to the appropriate handler.
    -- called by the middleware chain as the final step, or directly when
    -- no middleware is registered.
    -- @param update table the update object to dispatch
    -- @return any the return value of the matched handler
    function api._dispatch_update(update)
        api.on_update(update)
        -- framework layer (commands, hears, conversations) runs first; if it
        -- fully handles the update the legacy on_* handlers are skipped.
        if api._framework_handle and api._framework_handle(update) then
            return true
        end
        for _, utype in ipairs(api._update_types) do
            local payload = update[utype]
            if payload then
                local scoped = chat_scoped_handlers[utype]
                if scoped and payload.chat then
                    local scoped_handler = scoped[payload.chat.type]
                    if scoped_handler then
                        api[scoped_handler](payload)
                    end
                end
                return api['on_' .. utype](payload)
            end
        end
        return false
    end

    --- process an update through the middleware chain (if any) then dispatch.
    -- @param update table the update object to process
    -- @return any the return value of the matched handler, or false
    function api.process_update(update)
        if not update then
            return false
        end
        if #api._middleware > 0 or (api._scoped_middleware and next(api._scoped_middleware)) then
            return api._run_middleware(update)
        end
        return api._dispatch_update(update)
    end

    --- start the bot's polling loop.
    -- by default uses copas for concurrent update processing.
    -- pass { sync = true } for single-threaded sequential processing.
    -- @param opts table optional parameters
    -- @param opts.sync boolean use synchronous polling instead of async
    -- @param opts.limit number max number of updates per poll (default 1)
    -- @param opts.timeout number long-polling timeout in seconds (default 0)
    -- @param opts.offset number identifier of the first update to be returned
    -- @param opts.allowed_updates table list of update types to receive
    function api.run(opts)
        opts = opts or {}
        if opts.sync then
            return api._run_sync(opts)
        end
        -- default: async via copas
        return api.async.run(opts)
    end

    --- request that the synchronous polling loop exit at its next iteration.
    function api.stop_sync()
        api._sync_running = false
    end

    --- single-threaded synchronous polling loop (opt-in via sync = true).
    -- @param opts table same options as api.run
    function api._run_sync(opts)
        opts = opts or {}
        local limit = tonumber(opts.limit) or 1
        local timeout = tonumber(opts.timeout) or 0
        local offset = tonumber(opts.offset) or 0
        local allowed_updates = opts.allowed_updates
        local use_beta_endpoint = opts.use_beta_endpoint
        api._sync_running = true
        -- backoff state for transient polling failures: start at 1s, double
        -- on each consecutive failure up to 30s, reset on the next success.
        local backoff = 1
        local max_backoff = 30
        -- sleeper is injectable so tests can fast-forward backoff without
        -- the loop actually sleeping. defaults to the shared blocking sleep
        -- (socket.sleep when available; avoids spawning a shell).
        local sleeper = opts._sleeper or api._blocking_sleep
        while api._sync_running do
            local pok, updates, perr = pcall(api.get_updates, {
                timeout = timeout,
                offset = offset,
                limit = limit,
                allowed_updates = allowed_updates,
                use_beta_endpoint = use_beta_endpoint
            })
            if not pok then
                if api.debug then
                    print('Polling error [' .. tostring(updates) .. '], backing off ' .. backoff .. 's')
                end
                sleeper(backoff)
                backoff = math.min(backoff * 2, max_backoff)
            elseif updates and type(updates) == 'table' and updates.result then
                backoff = 1
                for _, v in ipairs(updates.result) do
                    -- protect the loop: a throwing handler must not kill the bot.
                    local ok, err = pcall(api.process_update, v)
                    if not ok and api.debug then
                        print('Update handler error: ' .. tostring(err))
                    end
                    offset = v.update_id + 1
                    if api.metrics then api.metrics.incr('updates') end
                end
            else
                -- get_updates returned false or a malformed payload. back off
                -- so a sustained server-side error doesn't pin a cpu. a 409 is a
                -- configuration error (duplicate poller / webhook still set),
                -- not transient, so surface it loudly.
                if type(perr) == 'table' and tonumber(perr.error_code) == 409 then
                    api.log.warn('polling conflict (409): another getUpdates is running for this ' ..
                        'bot, or a webhook is still set. stop the other instance or call ' ..
                        'api.delete_webhook().')
                elseif api.debug then
                    print('Polling returned no result, backing off ' .. backoff .. 's')
                end
                sleeper(backoff)
                backoff = math.min(backoff * 2, max_backoff)
            end
        end
    end
end
