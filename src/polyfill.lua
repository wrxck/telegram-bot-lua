--[[
    Polyfill module for Lua 5.1+ compatibility.
    Provides bit operations, table.unpack, and string.pack/unpack
    across Lua 5.1, 5.2, 5.3, 5.4, and 5.5.
]]

local polyfill = {}

local lua_version = tonumber(_VERSION:match('(%d+%.%d+)'))

-- Bit operations --

if lua_version >= 5.3 then
    -- Lua 5.3+: compile native operator syntax
    polyfill.band = load('return function(a,b) return a & b end')()
    polyfill.bor = load('return function(a,b) return a | b end')()
    polyfill.bxor = load('return function(a,b) return a ~ b end')()
    polyfill.bnot = load('return function(a) return (~a) & 0xFFFFFFFF end')()
    polyfill.lshift = load('return function(a,b) return a << b end')()
    polyfill.rshift = load('return function(a,b) return a >> b end')()
else
    -- Lua 5.2: bit32 is a built-in global
    -- Lua 5.1 + LuaJIT: try the 'bit' library
    -- Lua 5.1 plain: pure Lua fallback
    local bit_lib = rawget(_G, 'bit32')
    if not bit_lib then
        local ok, lib = pcall(require, 'bit')
        if ok then
            bit_lib = lib
        end
    end

    if bit_lib then
        polyfill.band = bit_lib.band
        polyfill.bor = bit_lib.bor
        polyfill.bxor = bit_lib.bxor
        polyfill.bnot = bit_lib.bnot
        polyfill.lshift = bit_lib.lshift
        polyfill.rshift = bit_lib.rshift
    else
        -- Pure Lua fallback for Lua 5.1 without bit library.
        -- Operates on non-negative integers up to 2^32.
        local floor = math.floor

        function polyfill.band(a, b)
            a, b = a % 0x100000000, b % 0x100000000
            local result, bit = 0, 1
            for _ = 1, 32 do
                if a % 2 == 1 and b % 2 == 1 then
                    result = result + bit
                end
                a = floor(a / 2)
                b = floor(b / 2)
                bit = bit * 2
            end
            return result
        end

        function polyfill.bor(a, b)
            a, b = a % 0x100000000, b % 0x100000000
            local result, bit = 0, 1
            for _ = 1, 32 do
                if a % 2 == 1 or b % 2 == 1 then
                    result = result + bit
                end
                a = floor(a / 2)
                b = floor(b / 2)
                bit = bit * 2
            end
            return result
        end

        function polyfill.bxor(a, b)
            a, b = a % 0x100000000, b % 0x100000000
            local result, bit = 0, 1
            for _ = 1, 32 do
                local a_bit, b_bit = a % 2, b % 2
                if a_bit ~= b_bit then
                    result = result + bit
                end
                a = floor(a / 2)
                b = floor(b / 2)
                bit = bit * 2
            end
            return result
        end

        function polyfill.bnot(a)
            return 0xFFFFFFFF - (a % 0x100000000)
        end

        function polyfill.lshift(a, n)
            return (a * (2 ^ n)) % 0x100000000
        end

        function polyfill.rshift(a, n)
            return floor((a % 0x100000000) / (2 ^ n))
        end
    end
end

-- table.unpack: available as table.unpack in 5.2+, as unpack in 5.1

polyfill.table_unpack = table.unpack or unpack

-- string.pack / string.unpack: native in 5.3+, compat53 for 5.1/5.2

if string.pack then
    polyfill.string_pack = string.pack
    polyfill.string_unpack = string.unpack
    polyfill.string_packsize = string.packsize
else
    -- Try compat53 for string.pack/unpack on 5.1/5.2
    local ok = pcall(require, 'compat53.string')
    if ok and string.pack then
        polyfill.string_pack = string.pack
        polyfill.string_unpack = string.unpack
        polyfill.string_packsize = string.packsize
    else
        -- Try the standalone struct library
        local sok, struct = pcall(require, 'struct')
        if sok then
            polyfill.string_pack = struct.pack
            polyfill.string_unpack = struct.unpack
            polyfill.string_packsize = struct.size
        else
            -- Graceful degradation: functions that use pack/unpack will
            -- return errors on 5.1/5.2 without compat53
            polyfill.string_pack = function()
                return nil, 'string.pack requires Lua 5.3+ or the compat53 library'
            end
            polyfill.string_unpack = function()
                return nil, 'string.unpack requires Lua 5.3+ or the compat53 library'
            end
            polyfill.string_packsize = function()
                return nil, 'string.packsize requires Lua 5.3+ or the compat53 library'
            end
        end
    end
end

return polyfill
