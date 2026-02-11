return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.send_checklist(chat_id, checklist, opts)
        opts = opts or {}
        checklist = type(checklist) == 'table' and json.encode(checklist) or checklist
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
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

    function api.add_checklist_tasks(chat_id, message_id, tasks)
        tasks = type(tasks) == 'table' and json.encode(tasks) or tasks
        local success, res = api.request(config.endpoint .. api.token .. '/addChecklistTasks', {
            ['chat_id'] = chat_id,
            ['message_id'] = message_id,
            ['tasks'] = tasks
        })
        return success, res
    end
end
