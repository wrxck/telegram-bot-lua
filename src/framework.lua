--- framework layer: rich context, command router, and conversations.
-- all additive and opt-in: if no command/hears/conversation is registered the
-- dispatch path is unchanged and existing on_* handlers run as before.
-- @module telegram-bot-lua.framework
return function(api)

    local message_like = {
        message = true, edited_message = true, channel_post = true,
        edited_channel_post = true, business_message = true,
        edited_business_message = true
    }

    -- find the update field carrying the payload, using the canonical
    -- priority-ordered list shared with the dispatcher (api._update_types,
    -- defined in handlers.lua).
    local function detect(update)
        for _, f in ipairs(api._update_types) do
            if update[f] then return f, update[f] end
        end
    end

    --- build a rich context object from a raw update.
    -- @param update table the raw update
    -- @return table a ctx with update_type, payload, chat, from, session, and
    --   reply/reply_with_photo/answer convenience methods
    function api.build_context(update)
        local utype, payload = detect(update)
        local ctx = { api = api, update = update, update_type = utype, payload = payload }
        if payload then
            ctx[utype] = payload
            ctx.from = payload.from
            ctx.message = message_like[utype] and payload or payload.message
            ctx.chat = (ctx.message and ctx.message.chat) or payload.chat
            ctx.chat_id = ctx.chat and ctx.chat.id
        end
        if api.session then
            ctx.session = api.session.get(update)
        end
        function ctx.reply(text, opts)
            return api.send_message(ctx.chat_id, text, opts)
        end
        function ctx.reply_with_photo(photo, opts)
            return api.send_photo(ctx.chat_id, photo, opts)
        end
        function ctx.answer(opts)
            if ctx.callback_query then
                return api.answer_callback_query(ctx.callback_query.id, opts)
            end
        end
        return ctx
    end

    -- command router ------------------------------------------------------

    api._commands = {}
    api._hears = {}
    api._command_not_found = nil

    --- register a command handler.
    -- api.command('start', handler) or api.command('ban', { guard = fn }, handler)
    function api.command(name, opts_or_handler, handler)
        if type(opts_or_handler) == 'function' then
            handler, opts_or_handler = opts_or_handler, {}
        end
        api._commands[name] = { handler = handler, opts = opts_or_handler or {} }
        return api
    end

    --- register a text matcher; pattern is a lua pattern or a function(text)->any.
    function api.hears(pattern, handler)
        table.insert(api._hears, { pattern = pattern, handler = handler })
        return api
    end

    --- handler for a message that looks like a command but matches none.
    function api.on_command_not_found(handler)
        api._command_not_found = handler
        return api
    end

    local function matches(pattern, text)
        if type(pattern) == 'function' then return pattern(text) end
        return text:match(pattern)
    end

    local function run_command(entry, ctx)
        local opts = entry.opts or {}
        if opts.guard and not opts.guard(ctx) then
            if opts.on_denied then opts.on_denied(ctx) end
            return true
        end
        entry.handler(ctx)
        return true
    end

    -- conversations -------------------------------------------------------

    api._conversations = {}
    api._waiters = {}

    local function conv_key(ctx)
        return tostring(ctx.chat_id) .. ':' .. tostring(ctx.from and ctx.from.id)
    end

    --- register a named conversation (a function(ctx) that may call ctx.wait_for()).
    function api.conversation(name, fn)
        api._conversations[name] = fn
        return api
    end

    --- start a conversation for the user in `update`. ctx.wait_for() suspends the
    -- conversation until the user's next message/callback arrives and returns its
    -- ctx. works in both sync (plain coroutine) and async (copas thread) modes.
    -- @param fn function|string a conversation function or a registered name
    -- @param update table the triggering update
    function api.enter(fn, update)
        if type(fn) == 'string' then fn = api._conversations[fn] end
        assert(type(fn) == 'function', 'api.enter requires a conversation function or name')
        local ctx = api.build_context(update)
        local key = conv_key(ctx)
        if api.async and api.async._running then
            -- async: run as a copas thread so api calls inside yield correctly;
            -- wait_for blocks on a mailbox woken by _conversation_resume.
            local copas = require('copas')
            local mailbox = require('copas.queue').new()
            api._waiters[key] = { mailbox = mailbox }
            ctx.wait_for = function()
                -- block until a message is pushed; copas.queue defaults to a
                -- 10s pop timeout, so an explicit math.huge is required or a
                -- conversation would silently abort after ~10s of waiting.
                return mailbox:pop(math.huge)
            end
            copas.addthread(function()
                local ok, err = pcall(fn, ctx)
                api._waiters[key] = nil
                if not ok and api.debug then print('conversation error: ' .. tostring(err)) end
            end)
            return true
        end
        -- sync: plain coroutine, manually resumed by _conversation_resume.
        local co
        ctx.wait_for = function()
            api._waiters[key] = { co = co }
            return coroutine.yield()
        end
        co = coroutine.create(function()
            local ok, err = pcall(fn, ctx)
            api._waiters[key] = nil
            if not ok and api.debug then print('conversation error: ' .. tostring(err)) end
        end)
        local ok, err = coroutine.resume(co)
        if not ok and api.debug then print('conversation error: ' .. tostring(err)) end
        return ok
    end

    --- resume a pending conversation if this update is awaited by the user.
    -- @return boolean true if the update was consumed by a conversation
    function api._conversation_resume(ctx)
        local waiter = api._waiters[conv_key(ctx)]
        if not waiter then return false end
        if waiter.mailbox then
            waiter.mailbox:push(ctx)
            return true
        end
        coroutine.resume(waiter.co, ctx)
        return true
    end

    -- dispatch glue -------------------------------------------------------

    --- framework dispatch: conversations, then commands, then hears.
    -- returns true if the update was fully handled (skip the on_* handlers).
    function api._framework_handle(update)
        local has_conv = next(api._waiters) ~= nil
        local has_cmd = next(api._commands) ~= nil
        local has_hears = #api._hears > 0
        if not (has_conv or has_cmd or has_hears) then
            return false
        end
        local msg = update.message
        if not (msg or update.callback_query) then
            return false
        end
        local ctx = api.build_context(update)
        if has_conv and api._conversation_resume(ctx) then
            return true
        end
        if msg and type(msg.text) == 'string' then
            if has_cmd then
                local cmd = api.extract_command(msg)
                if cmd and cmd.command then
                    ctx.command = cmd.command
                    ctx.args = cmd.args
                    ctx.args_str = cmd.args_str
                    local entry = api._commands[cmd.command]
                    if entry then
                        return run_command(entry, ctx)
                    elseif api._command_not_found then
                        api._command_not_found(ctx)
                        return true
                    end
                end
            end
            if has_hears then
                for _, h in ipairs(api._hears) do
                    local m = matches(h.pattern, msg.text)
                    if m then
                        ctx.match = m
                        h.handler(ctx)
                        return true
                    end
                end
            end
        end
        return false
    end
end
