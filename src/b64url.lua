--[[

       _       _                                      _           _          _
      | |     | |                                    | |         | |        | |
      | |_ ___| | ___  __ _ _ __ __ _ _ __ ___ ______| |__   ___ | |_ ______| |_   _  __ _
      | __/ _ \ |/ _ \/ _` | '__/ _` | '_ ` _ \______| '_ \ / _ \| __|______| | | | |/ _` |
      | ||  __/ |  __/ (_| | | | (_| | | | | | |     | |_) | (_) | |_       | | |_| | (_| |
       \__\___|_|\___|\__, |_|  \__,_|_| |_| |_|     |_.__/ \___/ \__|      |_|\__,_|\__,_|
                       __/ |
                      |___/

      Version 2.0-0
      Copyright (c) 2017-2024 Matthew Hesketh
      See LICENSE for details

      Adapted version of Paul Moore's base64 library (2017) updated for Lua 5.3 and upwards.
]] local b64url = {}

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
-- The input can be any string of arbitrary bytes.
--
-- @param input The input string.
-- @return The Base64 representation of the input string.
function b64url.encode(input)
    local out = {}
    -- Go through each triplet of 3 bytes, which produce 4 octets.
    local i = 1
    local bytes = {input:byte(i, #input)}
    while i <= #bytes - 2 do
        local buffer = 0
        -- Fill the buffer with the bytes, producing a 24-bit integer.
        local b = bytes[i] << 16
        buffer = buffer | (b & 0xff0000)
        buffer = buffer | ((bytes[i + 1] << 8) & 0xff00)
        buffer = buffer | (bytes[i + 2] & 0xff)
        -- Read out the 4 octets into the output buffer.
        b = (buffer >> 18) & 0x3f
        out[#out + 1] = encodable[b + 1]
        b = (buffer >> 12) & 0x3f
        out[#out + 1] = encodable[b + 1]
        b = (buffer >> 6) & 0x3f
        out[#out + 1] = encodable[b + 1]
        b = buffer & 0x3f
        out[#out + 1] = encodable[b + 1]
        i = i + 3
    end
    -- Special case 1: One byte extra, will produce 2 octets.
    if #bytes % 3 == 1 then
        local buffer = (bytes[i] << 16) & 0xff0000
        local b = (buffer >> 18) & 0x3f
        out[#out + 1] = encodable[b + 1]
        b = (buffer >> 12) & 0x3f
        out[#out + 1] = encodable[b + 1]
        -- Special case 2: Two bytes extra, will produce 3 octets.
    elseif #bytes % 3 == 2 then
        local buffer = 0
        local b = (bytes[i] << 16) & 0xff0000
        buffer = buffer | b
        b = (bytes[i + 1] << 8) & 0xff00
        buffer = buffer | b
        b = (buffer >> 18) & 0x3f
        out[#out + 1] = encodable[b + 1]
        b = (buffer >> 12) & 0x3f
        out[#out + 1] = encodable[b + 1]
        b = (buffer >> 6) & 0x3f
        out[#out + 1] = encodable[b + 1]
    end
    return table.concat(out)
end

--- Decodes a Base64 string into an output string of arbitrary bytes.
-- Currently does not check the input for valid Base64, so be careful.
--
-- @param input The Base64 input to decode.
-- @return The decoded Base64 string, as a string of bytes.
function b64url.decode(input)
    local out = {}
    -- Go through each group of 4 octets to obtain 3 bytes.
    local i = 1
    while i <= #input - 3 do
        -- Read the 4 octets into the buffer, producing a 24-bit integer.
        local b = decodable[input:byte(i) - 44] << 18
        local buffer = 0 | b
        i = i + 1
        b = decodable[input:byte(i) - 44] << 12
        buffer = buffer | b
        i = i + 1
        b = decodable[input:byte(i) - 44] << 6
        buffer = buffer | b
        i = i + 1
        b = decodable[input:byte(i) - 44]
        buffer = buffer | b
        i = i + 1
        -- Append the 3 re-constructed bytes into the output buffer.
        b = (buffer >> 16) & 0xff
        out[#out + 1] = b
        b = (buffer >> 8) & 0xff
        out[#out + 1] = b
        b = buffer & 0xff
        out[#out + 1] = b
    end

    -- Special case 1: Only 2 octets remain, producing 1 byte.
    if #input % 4 == 2 then
        local buffer = 0
        local b = decodable[input:byte(i) - 44] << 18
        buffer = buffer | b
        i = i + 1
        b = decodable[input:byte(i) - 44] << 12
        buffer = buffer | b
        i = i + 1
        b = (buffer >> 16) & 0xff
        out[#out + 1] = b
        -- Special case 2: Only 3 octets remain, producing 2 bytes.
    elseif #input % 4 == 3 then
        local buffer = 0
        local b = decodable[input:byte(i) - 44] << 18
        buffer = buffer | b
        i = i + 1
        b = decodable[input:byte(i) - 44] << 12
        buffer = buffer | b
        i = i + 1
        b = decodable[input:byte(i) - 44] << 6
        buffer = buffer | b
        i = i + 1
        b = (buffer >> 16) & 0xff
        out[#out + 1] = b
        b = (buffer >> 8) & 0xff
        out[#out + 1] = b
    end
    return string.char(table.unpack(out))
end

return b64url
