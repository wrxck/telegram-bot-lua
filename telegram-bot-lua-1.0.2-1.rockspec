rockspec_format = "1.0.2"
package = "telegram-bot-lua"
version = "1.0.2-1"

source = {
    url = "git://github.com/wrxck/telegram-bot-lua.git",
    dir = "telegram-bot-lua",
    branch = "master"
}

description = {
    summary = "A simple yet extensive Lua library for the Telegram bot API.",
    detailed = "A simple yet extensive Lua library for the Telegram bot API, with many tools and API-friendly functions.",
    license = "GPL-3",
    homepage = "https://github.com/wrxck/telegram-bot-lua",
    maintainer = "Matthew Hesketh <wrxck0@gmail.com>"
}

supported_platforms = {
    "linux",
    "macosx"
}

dependencies = {
    "dkjson >= 2.5-2",
    "lpeg >= 1.0.1-1",
    "luasec >= 0.6-1",
    "luasocket >= 3.0rc1-2",
    "multipart-post >= 1.1-1"
}

build = {
    type = "builtin",
    modules = {
        ["telegram-bot-lua.core"] = "src/core.lua",
        ["telegram-bot-lua.tools"] = "src/tools.lua"
    }
}