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

-- octet -> char encoding
local encodable = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
                   'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
                   'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
                   '8', '9', '-', '_'}

-- char byte -> 6-bit value, derived from the alphabet above so the two
-- tables can never drift apart. any byte not in the alphabet maps to nil,
-- which decode reports as an error instead of raising.
local decodable = {}
for index, char in ipairs(encodable) do
    decodable[char:byte()] = index - 1
end

--- Encodes a string into a Base64 string.
function b64url.encode(input)
    local out = {}
    local len = #input
    local i = 1
    -- read three bytes at a time straight from the string; materializing
    -- the whole byte array via input:byte(1, #input) overflowed the lua
    -- stack for inputs around 1 MB.
    while i + 2 <= len do
        local b1, b2, b3 = input:byte(i, i + 2)
        local buffer = bor(bor(lshift(b1, 16), lshift(b2, 8)), b3)
        out[#out + 1] = encodable[band(rshift(buffer, 18), 0x3f) + 1]
            .. encodable[band(rshift(buffer, 12), 0x3f) + 1]
            .. encodable[band(rshift(buffer, 6), 0x3f) + 1]
            .. encodable[band(buffer, 0x3f) + 1]
        i = i + 3
    end
    -- One byte extra: 2 octets.
    if len % 3 == 1 then
        local buffer = lshift(input:byte(i), 16)
        out[#out + 1] = encodable[band(rshift(buffer, 18), 0x3f) + 1]
            .. encodable[band(rshift(buffer, 12), 0x3f) + 1]
    -- Two bytes extra: 3 octets.
    elseif len % 3 == 2 then
        local b1, b2 = input:byte(i, i + 1)
        local buffer = bor(lshift(b1, 16), lshift(b2, 8))
        out[#out + 1] = encodable[band(rshift(buffer, 18), 0x3f) + 1]
            .. encodable[band(rshift(buffer, 12), 0x3f) + 1]
            .. encodable[band(rshift(buffer, 6), 0x3f) + 1]
    end
    return table.concat(out)
end

--- Decodes a Base64 string into an output string of arbitrary bytes.
-- Accepts padded and unpadded input. Returns nil and an error message for
-- input containing bytes outside the base64url alphabet or with an
-- impossible length, rather than raising.
function b64url.decode(input)
    -- '=' padding carries no data; strip it rather than decoding it as 0,
    -- which used to append spurious NUL bytes.
    input = input:gsub('=+$', '')
    local len = #input
    if len % 4 == 1 then
        return nil, 'invalid base64url input length'
    end
    local out = {}
    local i = 1
    while i + 3 <= len do
        local c1, c2, c3, c4 = input:byte(i, i + 3)
        local v1, v2, v3, v4 = decodable[c1], decodable[c2], decodable[c3], decodable[c4]
        if not (v1 and v2 and v3 and v4) then
            return nil, 'invalid base64url character'
        end
        local buffer = bor(bor(bor(lshift(v1, 18), lshift(v2, 12)), lshift(v3, 6)), v4)
        out[#out + 1] = string.char(
            band(rshift(buffer, 16), 0xff),
            band(rshift(buffer, 8), 0xff),
            band(buffer, 0xff))
        i = i + 4
    end
    -- 2 octets remain: 1 byte.
    if len % 4 == 2 then
        local v1, v2 = decodable[input:byte(i)], decodable[input:byte(i + 1)]
        if not (v1 and v2) then
            return nil, 'invalid base64url character'
        end
        local buffer = bor(lshift(v1, 18), lshift(v2, 12))
        out[#out + 1] = string.char(band(rshift(buffer, 16), 0xff))
    -- 3 octets remain: 2 bytes.
    elseif len % 4 == 3 then
        local v1, v2, v3 = decodable[input:byte(i)], decodable[input:byte(i + 1)], decodable[input:byte(i + 2)]
        if not (v1 and v2 and v3) then
            return nil, 'invalid base64url character'
        end
        local buffer = bor(bor(lshift(v1, 18), lshift(v2, 12)), lshift(v3, 6))
        out[#out + 1] = string.char(
            band(rshift(buffer, 16), 0xff),
            band(rshift(buffer, 8), 0xff))
    end
    return table.concat(out)
end

return b64url
