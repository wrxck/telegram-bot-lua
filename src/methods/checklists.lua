--- checklists API methods.
-- @module telegram-bot-lua.methods.checklists
return function(api)
    local config = require('telegram-bot-lua.config')

    --- send a checklist message to a chat.
    -- @param chat_id string|number unique identifier for the target chat
    -- @param checklist string|table JSON-serialised checklist object or a table thereof
    -- @param opts table optional parameters (disable_notification, protect_content, reply_parameters, reply_markup)
    -- @return table|false the sent message, or false on failure
    -- @return string|table the HTTP status or error details
    function api.send_checklist(chat_id, checklist, opts)
        opts = opts or {}
        checklist = api._json_enc(checklist)
        local reply_parameters = opts.reply_parameters
        reply_parameters = api._json_enc(reply_parameters)
        local reply_markup = opts.reply_markup
        reply_markup = api._json_enc(reply_markup)
        local success, res = api.request(config.endpoint .. api.token .. '/sendChecklist', {
            ['chat_id'] = chat_id,
            ['checklist'] = checklist,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup
        })
        return success, res
    end

    --- edit a task within an existing checklist message.
    -- @param chat_id string|number unique identifier for the target chat
    -- @param message_id number identifier of the checklist message
    -- @param checklist_task_id string identifier of the task to edit
    -- @param opts table optional parameters (text, is_completed)
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.edit_checklist(chat_id, message_id, checklist_task_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/editChecklist', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['checklist_task_id'] = checklist_task_id,
            ['text'] = opts.text,
            ['is_completed'] = opts.is_completed
        })
        return success, res
    end

    --- add new tasks to an existing checklist message.
    -- @param chat_id string|number unique identifier for the target chat
    -- @param message_id number identifier of the checklist message
    -- @param tasks string|table JSON-serialised array of tasks or a table thereof
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.add_checklist_tasks(chat_id, message_id, tasks)
        tasks = api._json_enc(tasks)
        local success, res = api.request(config.endpoint .. api.token .. '/addChecklistTasks', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['tasks'] = tasks
        })
        return success, res
    end

    --- edit a checklist on behalf of a connected business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param chat_id string|number unique identifier for the target chat
    -- @param message_id number unique identifier for the target message
    -- @param checklist string|table a JSON-serialised InputChecklist object or a table thereof
    -- @param opts table optional parameters
    -- @param opts.reply_markup string|table a JSON-serialised object for the new inline keyboard
    -- @return table|false the edited message, or false on failure
    -- @return string|table the HTTP status or error details
    function api.edit_message_checklist(business_connection_id, chat_id, message_id, checklist, opts)
        opts = opts or {}
        checklist = api._json_enc(checklist)
        local reply_markup = opts.reply_markup
        reply_markup = api._json_enc(reply_markup)
        local success, res = api.request(config.endpoint .. api.token .. '/editMessageChecklist', {
            ['business_connection_id'] = business_connection_id,
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['checklist'] = checklist,
            ['reply_markup'] = reply_markup
        })
        return success, res
    end
end
