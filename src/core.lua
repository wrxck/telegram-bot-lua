-- Compatibility shim: require('telegram-bot-lua.core') now forwards to require('telegram-bot-lua')
io.stderr:write('[telegram-bot-lua] DEPRECATED: require("telegram-bot-lua.core") is deprecated, use require("telegram-bot-lua") instead\n')
return require('telegram-bot-lua')
