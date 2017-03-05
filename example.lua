--[[
    This example will echo messages back to the user who sent them, with an inline keyboard
    which tells the user what their numerical ID is.
]]

local api = require('telegram-bot-lua.core').configure('') -- Enter your token

function api.on_message(message)
    if message.text then
        api.send_message(
            message,
            message.text,
            nil,
            true,
            false,
            nil,
            api.inline_keyboard():row(
                api.row():callback_data_button(
                    'Button',
                    'callback_data'
                )
            )
        )
    end
end

function api.on_callback_query(callback_query)
    api.answer_callback_query(
        callback_query.id
        'Your ID is: ' .. callback_query.from.id
    )
end

api.run()