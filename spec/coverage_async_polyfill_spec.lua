-- coverage tests for src/async.lua (debug/409 branches inside async.run's
-- polling loop) and src/polyfill.lua (the Lua 5.1/5.2 fallback branches,
-- executed for real by loading the file with a sandboxed environment).
local api = require('spec.test_helper')
local copas = require('copas')

describe('async.run polling-loop branches', function()
    local original_get_updates, original_sleep, original_debug, original_warn
    local sleeps

    before_each(function()
        original_get_updates = api.get_updates
        original_sleep = copas.sleep
        original_debug = api.debug
        original_warn = api.log.warn
        sleeps = {}
        copas.sleep = function(s) table.insert(sleeps, s) end
        api._clear_requests()
    end)

    after_each(function()
        api.get_updates = original_get_updates
        copas.sleep = original_sleep
        api.debug = original_debug
        api.log.warn = original_warn
        api.async._running = false
    end)

    it('prints the polling error when api.debug is on', function()
        api.debug = true
        local calls = 0
        api.get_updates = function()
            calls = calls + 1
            if calls == 1 then
                error('simulated poll crash')
            end
            api.async.stop()
            return { ok = true, result = {} }, 200
        end
        local printed = {}
        local original_print = print
        _G.print = function(...) table.insert(printed, (...)) end
        api.async.run({ timeout = 0 })
        _G.print = original_print
        assert.equals(2, calls)
        assert.same({ 1 }, sleeps)
        local found = false
        for _, line in ipairs(printed) do
            if line:find('Polling error', 1, true) and line:find('simulated poll crash', 1, true) then
                found = true
            end
        end
        assert.is_true(found, 'expected a "Polling error [...]" debug line')
    end)

    it('prints handler errors when api.debug is on', function()
        api.debug = true
        local original_on_message = api.on_message
        api.on_message = function() error('handler exploded') end
        finally(function() api.on_message = original_on_message end)
        local calls = 0
        api.get_updates = function()
            calls = calls + 1
            if calls == 1 then
                return { ok = true, result = {
                    { update_id = 1, message = { chat = { id = 1, type = 'private' }, text = 'x' } }
                } }, 200
            end
            api.async.stop()
            return { ok = true, result = {} }, 200
        end
        local printed = {}
        local original_print = print
        _G.print = function(...) table.insert(printed, (...)) end
        api.async.run({ timeout = 0 })
        _G.print = original_print
        local found = false
        for _, line in ipairs(printed) do
            if line:find('Update handler error', 1, true) and line:find('handler exploded', 1, true) then
                found = true
            end
        end
        assert.is_true(found, 'expected an "Update handler error: ..." debug line')
    end)

    it('warns loudly on a 409 polling conflict instead of a debug print', function()
        api.debug = false
        local warnings = {}
        api.log.warn = function(...) table.insert(warnings, table.concat({ ... }, ' ')) end
        local calls = 0
        api.get_updates = function()
            calls = calls + 1
            if calls == 1 then
                return false, { ok = false, error_code = 409, description = 'Conflict' }
            end
            api.async.stop()
            return { ok = true, result = {} }, 200
        end
        api.async.run({ timeout = 0 })
        assert.equals(1, #warnings)
        assert.truthy(warnings[1]:find('polling conflict (409)', 1, true))
        assert.truthy(warnings[1]:find('delete_webhook', 1, true))
        -- still backs off before polling again
        assert.same({ 1 }, sleeps)
    end)

    it('prints the no-result backoff message when api.debug is on', function()
        api.debug = true
        local calls = 0
        api.get_updates = function()
            calls = calls + 1
            if calls == 1 then
                return false, 'connection refused'
            end
            api.async.stop()
            return { ok = true, result = {} }, 200
        end
        local printed = {}
        local original_print = print
        _G.print = function(...) table.insert(printed, (...)) end
        api.async.run({ timeout = 0 })
        _G.print = original_print
        local found = false
        for _, line in ipairs(printed) do
            if line:find('Polling returned no result', 1, true) then
                found = true
            end
        end
        assert.is_true(found, 'expected a "Polling returned no result" debug line')
    end)

    it('is_running reports true from inside the loop and false after', function()
        local seen_running
        api.get_updates = function()
            seen_running = api.async.is_running()
            api.async.stop()
            return { ok = true, result = {} }, 200
        end
        api.async.run({ timeout = 0 })
        assert.is_true(seen_running)
        assert.is_false(api.async.is_running())
    end)
end)

describe('polyfill fallback branches (sandboxed load)', function()
    -- load src/polyfill.lua with a custom environment so the version
    -- detection takes the Lua 5.1/5.2 paths for real. because the chunk name
    -- is the actual file path, the executed fallback lines are attributed to
    -- src/polyfill.lua by luacov.
    local function load_polyfill(env)
        env._VERSION = env._VERSION or 'Lua 5.1'
        env.tonumber = env.tonumber or tonumber
        env.pcall = env.pcall or pcall
        env.rawget = env.rawget or rawget
        env.math = env.math or math
        env._G = env._G or {}
        local chunk, err = loadfile('src/polyfill.lua', 't', env)
        assert.is_truthy(chunk, err)
        return chunk()
    end

    it('uses the bit library and struct library when available (5.1 + luajit-style)', function()
        local fake_bit = {
            band = function(a, b) return { 'band', a, b } end,
            bor = function() end, bxor = function() end,
            bnot = function() end, lshift = function() end, rshift = function() end,
        }
        local fake_struct = {
            pack = function() return 'packed' end,
            unpack = function() return 'unpacked' end,
            size = function() return 4 end,
        }
        local required = {}
        local poly = load_polyfill({
            table = { unpack = table.unpack },
            string = {},
            unpack = table.unpack,
            require = function(name)
                table.insert(required, name)
                if name == 'bit' then return fake_bit end
                if name == 'struct' then return fake_struct end
                error("module '" .. name .. "' not found")
            end,
        })
        -- bit ops are the fake library's functions, verbatim
        assert.equals(fake_bit.band, poly.band)
        assert.equals(fake_bit.bor, poly.bor)
        assert.equals(fake_bit.bxor, poly.bxor)
        assert.equals(fake_bit.bnot, poly.bnot)
        assert.equals(fake_bit.lshift, poly.lshift)
        assert.equals(fake_bit.rshift, poly.rshift)
        assert.same({ 'band', 3, 5 }, poly.band(3, 5))
        -- string.pack maps through struct
        assert.equals(fake_struct.pack, poly.string_pack)
        assert.equals(fake_struct.unpack, poly.string_unpack)
        assert.equals(fake_struct.size, poly.string_packsize)
        -- table.unpack came from env.table.unpack (5.2-style)
        assert.equals(table.unpack, poly.table_unpack)
        -- it really did probe require for the bit library
        assert.equals('bit', required[1])
    end)

    it('uses global bit32 and compat53 when present (5.2-style)', function()
        local fake_bit32 = {
            band = function() end, bor = function(a, b) return a + b end,
            bxor = function() end, bnot = function() end,
            lshift = function() end, rshift = function() end,
        }
        local env_string = {}
        local poly = load_polyfill({
            _VERSION = 'Lua 5.2',
            _G = { bit32 = fake_bit32 },
            table = { unpack = table.unpack },
            string = env_string,
            require = function(name)
                if name == 'compat53.string' then
                    -- compat53 injects pack/unpack into the string table
                    env_string.pack = string.pack
                    env_string.unpack = string.unpack
                    env_string.packsize = string.packsize
                    return true
                end
                error("module '" .. name .. "' not found")
            end,
        })
        assert.equals(fake_bit32.bor, poly.bor)
        assert.equals(7, poly.bor(3, 4))
        assert.equals(string.pack, poly.string_pack)
        assert.equals(string.unpack, poly.string_unpack)
        assert.equals(string.packsize, poly.string_packsize)
    end)

    describe('pure-Lua fallback (5.1, no bit library)', function()
        local poly

        setup(function()
            poly = load_polyfill({
                table = {},          -- no table.unpack: forces the `unpack` fallback
                unpack = table.unpack,
                string = {},         -- no string.pack, and no compat53/struct below
                require = function(name)
                    error("module '" .. name .. "' not found")
                end,
            })
        end)

        local samples = { 0, 1, 3, 0xFF, 0x0F0F, 0x12345678, 0xDEADBEEF, 0xFFFFFFFF }

        it('band/bor/bxor match the native 5.4 operators', function()
            for _, a in ipairs(samples) do
                for _, b in ipairs(samples) do
                    assert.equals(a & b, poly.band(a, b), ('band(%x,%x)'):format(a, b))
                    assert.equals(a | b, poly.bor(a, b), ('bor(%x,%x)'):format(a, b))
                    assert.equals(a ~ b, poly.bxor(a, b), ('bxor(%x,%x)'):format(a, b))
                end
            end
        end)

        it('bnot matches the native operator masked to 32 bits', function()
            for _, a in ipairs(samples) do
                assert.equals((~a) & 0xFFFFFFFF, poly.bnot(a), ('bnot(%x)'):format(a))
            end
        end)

        it('lshift matches the native operator masked to 32 bits', function()
            -- keep a * 2^n within float-exact range: values up to 0xFFFF
            for _, a in ipairs({ 0, 1, 3, 0xFF, 0xFFFF }) do
                for _, n in ipairs({ 0, 1, 4, 8, 16, 31 }) do
                    assert.equals((a << n) & 0xFFFFFFFF, poly.lshift(a, n),
                        ('lshift(%x,%d)'):format(a, n))
                end
            end
        end)

        it('rshift matches the native operator over the full 32-bit range', function()
            for _, a in ipairs(samples) do
                for _, n in ipairs({ 0, 1, 4, 8, 16, 31 }) do
                    assert.equals((a & 0xFFFFFFFF) >> n, poly.rshift(a, n),
                        ('rshift(%x,%d)'):format(a, n))
                end
            end
        end)

        it('falls back to the global unpack for table_unpack', function()
            assert.equals(table.unpack, poly.table_unpack)
            local x, y = poly.table_unpack({ 'a', 'b' })
            assert.equals('a', x)
            assert.equals('b', y)
        end)

        it('degrades string.pack/unpack/packsize to nil + an explanatory error', function()
            local packed, perr = poly.string_pack('<i4', 1)
            assert.is_nil(packed)
            assert.truthy(perr:find('compat53', 1, true))
            local unpacked, uerr = poly.string_unpack('<i4', 'x')
            assert.is_nil(unpacked)
            assert.truthy(uerr:find('compat53', 1, true))
            local size, serr = poly.string_packsize('<i4')
            assert.is_nil(size)
            assert.truthy(serr:find('compat53', 1, true))
        end)
    end)
end)
