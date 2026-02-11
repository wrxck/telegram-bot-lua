--[[

       _       _                                      _           _          _
      | |     | |                                    | |         | |        | |
      | |_ ___| | ___  __ _ _ __ __ _ _ __ ___ ______| |__   ___ | |_ ______| |_   _  __ _
      | __/ _ \ |/ _ \/ _` | '__/ _` | '_ ` _ \______| '_ \ / _ \| __|______| | | | |/ _` |
      | ||  __/ |  __/ (_| | | | (_| | | | | | |     | |_) | (_) | |_       | | |_| | (_| |
       \__\___|_|\___|\__, |_|  \__,_|_| |_| |_|     |_.__/ \___/ \__|      |_|\__,_|\__,_|
                       __/ |
                      |___/

      Version 3.0-0
      Copyright (c) 2017-2026 Matthew Hesketh
      See LICENSE for details

      Adapted version of Paul Moore's base64 library (2017).
      Compatible with Lua 5.1+ via polyfill.
]] local b64url = {}

local poly = require('telegram-bot-lua.polyfill')
local band, bor, lshift, rshift = poly.band, poly.bor, poly.lshift, poly.rshift
local tunpack = poly.table_unpack

--- octet -> char encoding.
local encodable = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
                   'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
                   'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
                   '8', '9', '-', '_'}

--- char -> octet encoding.
-- Offset by 44 (from index 1).
local decodable = {62, 0, 0, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
                   10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 63, 0, 26, 27, 28, 29,
                   30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51}

--- Encodes a string into a Base64 string.
function b64url.encode(input)
    local out = {}
    local i = 1
    local bytes = {input:byte(i, #input)}
    while i <= #bytes - 2 do
        local buffer = 0
        local b = lshift(bytes[i], 16)
        buffer = bor(buffer, band(b, 0xff0000))
        buffer = bor(buffer, band(lshift(bytes[i + 1], 8), 0xff00))
        buffer = bor(buffer, band(bytes[i + 2], 0xff))
        b = band(rshift(buffer, 18), 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = band(rshift(buffer, 12), 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = band(rshift(buffer, 6), 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = band(buffer, 0x3f)
        out[#out + 1] = encodable[b + 1]
        i = i + 3
    end
    -- One byte extra: 2 octets.
    if #bytes % 3 == 1 then
        local buffer = band(lshift(bytes[i], 16), 0xff0000)
        local b = band(rshift(buffer, 18), 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = band(rshift(buffer, 12), 0x3f)
        out[#out + 1] = encodable[b + 1]
    -- Two bytes extra: 3 octets.
    elseif #bytes % 3 == 2 then
        local buffer = 0
        local b = band(lshift(bytes[i], 16), 0xff0000)
        buffer = bor(buffer, b)
        b = band(lshift(bytes[i + 1], 8), 0xff00)
        buffer = bor(buffer, b)
        b = band(rshift(buffer, 18), 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = band(rshift(buffer, 12), 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = band(rshift(buffer, 6), 0x3f)
        out[#out + 1] = encodable[b + 1]
    end
    return table.concat(out)
end

--- Decodes a Base64 string into an output string of arbitrary bytes.
function b64url.decode(input)
    local out = {}
    local i = 1
    while i <= #input - 3 do
        local b = lshift(decodable[input:byte(i) - 44], 18)
        local buffer = bor(0, b)
        i = i + 1
        b = lshift(decodable[input:byte(i) - 44], 12)
        buffer = bor(buffer, b)
        i = i + 1
        b = lshift(decodable[input:byte(i) - 44], 6)
        buffer = bor(buffer, b)
        i = i + 1
        b = decodable[input:byte(i) - 44]
        buffer = bor(buffer, b)
        i = i + 1
        b = band(rshift(buffer, 16), 0xff)
        out[#out + 1] = b
        b = band(rshift(buffer, 8), 0xff)
        out[#out + 1] = b
        b = band(buffer, 0xff)
        out[#out + 1] = b
    end

    -- 2 octets remain: 1 byte.
    if #input % 4 == 2 then
        local buffer = 0
        local b = lshift(decodable[input:byte(i) - 44], 18)
        buffer = bor(buffer, b)
        i = i + 1
        b = lshift(decodable[input:byte(i) - 44], 12)
        buffer = bor(buffer, b)
        b = band(rshift(buffer, 16), 0xff)
        out[#out + 1] = b
    -- 3 octets remain: 2 bytes.
    elseif #input % 4 == 3 then
        local buffer = 0
        local b = lshift(decodable[input:byte(i) - 44], 18)
        buffer = bor(buffer, b)
        i = i + 1
        b = lshift(decodable[input:byte(i) - 44], 12)
        buffer = bor(buffer, b)
        i = i + 1
        b = lshift(decodable[input:byte(i) - 44], 6)
        buffer = bor(buffer, b)
        b = band(rshift(buffer, 16), 0xff)
        out[#out + 1] = b
        b = band(rshift(buffer, 8), 0xff)
        out[#out + 1] = b
    end
    return string.char(tunpack(out))
end

return b64url
