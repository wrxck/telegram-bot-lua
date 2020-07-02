--[[

       _       _                                      _           _          _
      | |     | |                                    | |         | |        | |
      | |_ ___| | ___  __ _ _ __ __ _ _ __ ___ ______| |__   ___ | |_ ______| |_   _  __ _
      | __/ _ \ |/ _ \/ _` | '__/ _` | '_ ` _ \______| '_ \ / _ \| __|______| | | | |/ _` |
      | ||  __/ |  __/ (_| | | | (_| | | | | | |     | |_) | (_) | |_       | | |_| | (_| |
       \__\___|_|\___|\__, |_|  \__,_|_| |_| |_|     |_.__/ \___/ \__|      |_|\__,_|\__,_|
                       __/ |
                      |___/

      Version 1.10-0
      Copyright (c) 2020 Matthew Hesketh
      See LICENSE for details

      Adapted version of Paul Moore's base64 library updated for Lua 5.2 and upwards.
      See original license below.
]]

-- Copyright (C) 2012 by Paul Moore
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local b64url = {}
local bit32 = bit32 or bit or require('bit')
assert(bit32, 'You don\'t have a valid bitwise library installed!')

--- octet -> char encoding.
local encodable = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
    'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
    'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', '-', '_'
}

--- char -> octet encoding.
-- Offset by 44 (from index 1).
local decodable = {
    62,  0,  0, 52, 53, 54, 55, 56, 57, 58,
    59, 60, 61,  0,  0,  0,  0,  0,  0,  0,
     0,  1,  2,  3,  4,  5,  6,  7,  8,  9,
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    20, 21, 22, 23, 24, 25,  0,  0,  0,  0,
    63,  0, 26, 27, 28, 29, 30, 31, 32, 33,
    34, 35, 36, 37, 38, 39, 40, 41, 42, 43,
    44, 45, 46, 47, 48, 49, 50, 51
}

--- Encodes a string into a Base64 string.
-- The input can be any string of arbitrary bytes.
--
-- @param input The input string.
-- @return The Base64 representation of the input string.
function b64url.encode(input)
    local out = {}
    -- Go through each triplet of 3 bytes, which produce 4 octets.
    local i = 1
    local bytes = { input:byte(i, #input) }
    while i <= #bytes - 2 do
        local buffer = 0
        -- Fill the buffer with the bytes, producing a 24-bit integer.
        local b = bit32.lshift(bytes[i], 16)
        b = bit32.band(b, 0xff0000)
        buffer = bit32.bor(buffer, b)
        b = bit32.lshift(bytes[i + 1], 8)
        b = bit32.band(b, 0xff00)
        buffer = bit32.bor(buffer, b)
        b = bit32.band(bytes[i + 2], 0xff)
        buffer = bit32.bor(buffer, b)
        -- Read out the 4 octets into the output buffer.
        b = bit32.rshift(buffer, 18)
        b = bit32.band(b, 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = bit32.rshift(buffer, 12)
        b = bit32.band(b, 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = bit32.rshift(buffer, 6)
        b = bit32.band(b, 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = bit32.band(buffer, 0x3f)
        out[#out + 1] = encodable[b + 1]
                i = i + 3
    end
    -- Special case 1: One byte extra, will produce 2 octets.
    if #bytes % 3 == 1 then
        local buffer = bit32.lshift(bytes[i], 16)
        buffer = bit32.band(buffer, 0xff0000)
        local b = bit32.rshift(buffer, 18)
        b = bit32.band(b, 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = bit32.rshift(buffer, 12)
        b = bit32.band(b, 0x3f)
        out[#out + 1] = encodable[b + 1]
    -- Special case 2: Two bytes extra, will produce 3 octets.
    elseif #bytes % 3 == 2 then
        local buffer = 0
        local b = bit32.lshift(bytes[i], 16)
        b = bit32.band(b, 0xff0000)
        buffer = bit32.bor(buffer, b)
        b = bit32.lshift(bytes[i + 1], 8)
        b = bit32.band(b, 0xff00)
        buffer = bit32.bor(buffer, b)

        b = bit32.rshift(buffer, 18)
        b = bit32.band(b, 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = bit32.rshift(buffer, 12)
        b = bit32.band(b, 0x3f)
        out[#out + 1] = encodable[b + 1]
        b = bit32.rshift(buffer, 6)
        b = bit32.band(b, 0x3f)
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
        local buffer = 0
        -- Read the 4 octets into the buffer, producing a 24-bit integer.
        local b = input:byte(i)
        b = decodable[b - 44]
        b = bit32.lshift(b, 18)
        buffer = bit32.bor(buffer, b)
        i = i + 1
        b = input:byte(i)
        b = decodable[b - 44]
        b = bit32.lshift(b, 12)
        buffer = bit32.bor(buffer, b)
        i = i + 1
        b = input:byte(i)
        b = decodable[b - 44]
        b = bit32.lshift(b, 6)
        buffer = bit32.bor(buffer, b)
        i = i + 1
        b = input:byte(i)
        b = decodable[b - 44]
        buffer = bit32.bor(buffer, b)
        i = i + 1
        -- Append the 3 re-constructed bytes into the output buffer.
        b = bit32.rshift(buffer, 16)
        b = bit32.band(b, 0xff)
        out[#out + 1] = b
        b = bit32.rshift(buffer, 8)
        b = bit32.band(b, 0xff)
        out[#out + 1] = b
        b = bit32.band(buffer, 0xff)
        out[#out + 1] = b
    end

    -- Special case 1: Only 2 octets remain, producing 1 byte.
    if #input % 4 == 2 then
        local buffer = 0
        local b = input:byte(i)
        b = decodable[b - 44]
        b = bit32.lshift(b, 18)
        buffer = bit32.bor(buffer, b)
        i = i + 1
        b = input:byte(i)
        b = decodable[b - 44]
        b = bit32.lshift(b, 12)
        buffer = bit32.bor(buffer, b)
        i = i + 1
        b = bit32.rshift(buffer, 16)
        b = bit32.band(b, 0xff)
        out[#out + 1] = b
    -- Special case 2: Only 3 octets remain, producing 2 bytes.
    elseif #input % 4 == 3 then
        local buffer = 0
        local b = input:byte(i)
        b = decodable[b - 44]
        b = bit32.lshift(b, 18)
        buffer = bit32.bor(buffer, b)
        i = i + 1
        b = input:byte(i)
        b = decodable[b - 44]
        b = bit32.lshift(b, 12)
        buffer = bit32.bor(buffer, b)
        i = i + 1
        b = input:byte(i)
        b = decodable[b - 44]
        b = bit32.lshift(b, 6)
        buffer = bit32.bor(buffer, b)
        i = i + 1
        b = bit32.rshift(buffer, 16)
        b = bit32.band(b, 0xff)
        out[#out + 1] = b
        b = bit32.rshift(buffer, 8)
        b = bit32.band(b, 0xff)
        out[#out + 1] = b
    end
    return string.char(table.unpack(out))
end

return b64url