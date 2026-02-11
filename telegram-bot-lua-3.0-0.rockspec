package = "telegram-bot-lua"
version = "3.0-0"
source = {
    url = "git://github.com/wrxck/telegram-bot-lua.git",
    dir = "telegram-bot-lua",
    tag = "v3.0"
}
description = {
    summary = "A feature-filled Telegram bot API library",
    detailed = "A feature-filled Telegram bot API library written in Lua, with Bot API 9.4 support.",
    homepage = "https://github.com/wrxck/telegram-bot-lua",
    maintainer = "Matthew Hesketh <matthew@matthewhesketh.com>",
    license = "GPL-3"
}
supported_platforms = {
    "linux",
    "macosx",
    "unix",
    "bsd"
}
dependencies = {
    "lua >= 5.1",
    "dkjson >= 2.5-2",
    "luasec >= 0.6-1",
    "luasocket >= 3.0rc1-2",
    "multipart-post >= 1.1-1",
    "luautf8 >= 0.1.1-1",
    "copas >= 4.0"
}
build = {
    type = "builtin",
    modules = {
        ["telegram-bot-lua"] = "src/init.lua",
        ["telegram-bot-lua.config"] = "src/config.lua",
        ["telegram-bot-lua.handlers"] = "src/handlers.lua",
        ["telegram-bot-lua.builders"] = "src/builders.lua",
        ["telegram-bot-lua.helpers"] = "src/helpers.lua",
        ["telegram-bot-lua.tools"] = "src/tools.lua",
        ["telegram-bot-lua.utils"] = "src/utils.lua",
        ["telegram-bot-lua.compat"] = "src/compat.lua",
        ["telegram-bot-lua.core"] = "src/core.lua",
        ["telegram-bot-lua.polyfill"] = "src/polyfill.lua",
        ["telegram-bot-lua.async"] = "src/async.lua",
        ["telegram-bot-lua.b64url"] = "src/b64url.lua",
        ["telegram-bot-lua.methods.updates"] = "src/methods/updates.lua",
        ["telegram-bot-lua.methods.messages"] = "src/methods/messages.lua",
        ["telegram-bot-lua.methods.chat"] = "src/methods/chat.lua",
        ["telegram-bot-lua.methods.members"] = "src/methods/members.lua",
        ["telegram-bot-lua.methods.forum"] = "src/methods/forum.lua",
        ["telegram-bot-lua.methods.stickers"] = "src/methods/stickers.lua",
        ["telegram-bot-lua.methods.inline"] = "src/methods/inline.lua",
        ["telegram-bot-lua.methods.payments"] = "src/methods/payments.lua",
        ["telegram-bot-lua.methods.games"] = "src/methods/games.lua",
        ["telegram-bot-lua.methods.passport"] = "src/methods/passport.lua",
        ["telegram-bot-lua.methods.bot"] = "src/methods/bot.lua",
        ["telegram-bot-lua.methods.gifts"] = "src/methods/gifts.lua",
        ["telegram-bot-lua.methods.checklists"] = "src/methods/checklists.lua",
        ["telegram-bot-lua.methods.stories"] = "src/methods/stories.lua",
        ["telegram-bot-lua.methods.suggested_posts"] = "src/methods/suggested_posts.lua"
    }
}
