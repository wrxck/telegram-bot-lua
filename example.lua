local api = require('telegram-bot-lua.core').configure('') -- Enter your token

function api.on_message(message)
    if message.text then
        api.send_message(
            message,
            message.text
        )
    end
end

api.run()