--- middleware system for intercepting and processing updates.
-- @module telegram-bot-lua.middleware
return function(api)

    api._middleware = {}
    api._scoped_middleware = {}

    --- register a global middleware function.
    -- @param fn function middleware receiving (ctx, next) arguments
    function api.use(fn)
        table.insert(api._middleware, fn)
    end

    -- Compose a list of middleware functions into a single function.
    -- Each middleware receives (ctx, next) where next() continues the chain.
    local function compose(middleware, ctx, final)
        local index = 0
        local function dispatch(i)
            if i <= index then
                error('next() called multiple times')
            end
            index = i
            local fn = middleware[i]
            if not fn then
                if final then final(ctx) end
                return
            end
            fn(ctx, function()
                dispatch(i + 1)
            end)
        end
        dispatch(1)
    end

    -- Build the context object from a raw update. Uses the canonical update
    -- type list shared with the dispatcher (api._update_types, defined in
    -- handlers.lua) so middleware and handlers always agree on update types.
    local function build_context(update)
        local ctx = { update = update }
        for _, utype in ipairs(api._update_types) do
            if update[utype] then
                ctx.update_type = utype
                ctx[utype] = update[utype]
                break
            end
        end
        return ctx
    end

    --- execute the middleware chain then dispatch to handlers.
    -- @param update table the raw update object
    function api._run_middleware(update)
        local ctx = build_context(update)

        -- Collect applicable middleware: global + scoped
        local chain = {}
        for i = 1, #api._middleware do
            chain[#chain + 1] = api._middleware[i]
        end
        local scoped = ctx.update_type and api._scoped_middleware[ctx.update_type]
        if scoped then
            for i = 1, #scoped do
                chain[#chain + 1] = scoped[i]
            end
        end

        -- Final function: dispatch to the original handlers
        local function dispatch(c)
            api._dispatch_update(c.update)
        end

        compose(chain, ctx, dispatch)
    end

    -- Scoped middleware registration.
    -- Returns a callable table so api.on_message(...) still works as a handler setter,
    -- and api.on_message.use(fn) registers scoped middleware.
    function api._register_scoped_middleware(update_type)
        return {
            use = function(fn)
                if not api._scoped_middleware[update_type] then
                    api._scoped_middleware[update_type] = {}
                end
                table.insert(api._scoped_middleware[update_type], fn)
            end
        }
    end

    -- Expose scoped middleware tables
    api.middleware = {
        on_message = api._register_scoped_middleware('message'),
        on_callback_query = api._register_scoped_middleware('callback_query'),
        on_inline_query = api._register_scoped_middleware('inline_query'),
        on_channel_post = api._register_scoped_middleware('channel_post'),
        on_edited_message = api._register_scoped_middleware('edited_message'),
        on_edited_channel_post = api._register_scoped_middleware('edited_channel_post'),
        on_chosen_inline_result = api._register_scoped_middleware('chosen_inline_result'),
        on_shipping_query = api._register_scoped_middleware('shipping_query'),
        on_pre_checkout_query = api._register_scoped_middleware('pre_checkout_query'),
        on_poll = api._register_scoped_middleware('poll'),
        on_poll_answer = api._register_scoped_middleware('poll_answer'),
        on_message_reaction = api._register_scoped_middleware('message_reaction'),
        on_message_reaction_count = api._register_scoped_middleware('message_reaction_count'),
        on_my_chat_member = api._register_scoped_middleware('my_chat_member'),
        on_chat_member = api._register_scoped_middleware('chat_member'),
        on_chat_join_request = api._register_scoped_middleware('chat_join_request'),
        on_chat_boost = api._register_scoped_middleware('chat_boost'),
        on_removed_chat_boost = api._register_scoped_middleware('removed_chat_boost'),
        on_business_connection = api._register_scoped_middleware('business_connection'),
        on_business_message = api._register_scoped_middleware('business_message'),
        on_edited_business_message = api._register_scoped_middleware('edited_business_message'),
        on_deleted_business_messages = api._register_scoped_middleware('deleted_business_messages'),
        on_purchased_paid_media = api._register_scoped_middleware('purchased_paid_media'),
    }
end
