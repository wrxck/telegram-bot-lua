-- regression tests for tools/b64url issues found during the quality review.
local api = require('spec.test_helper')
local tools = require('telegram-bot-lua.tools')
local b64url = require('telegram-bot-lua.b64url')

describe('quality review: b64url', function()
    it('decodes padded input without spurious NUL bytes', function()
        -- '=' padding was decoded as data (value 0), appending NULs.
        assert.equals('M', b64url.decode('TQ=='))
        assert.equals('Ma', b64url.decode('TWE='))
    end)

    it('returns nil for invalid characters instead of raising', function()
        local decoded, err = b64url.decode('++++')
        assert.is_nil(decoded)
        assert.is_string(err)
    end)

    it('returns nil for an impossible length remainder of 1', function()
        local decoded, err = b64url.decode('TWFuQ')
        assert.is_nil(decoded)
        assert.is_string(err)
    end)

    it('round-trips large inputs without a stack overflow', function()
        local input = string.rep('x', 1000000)
        local encoded = b64url.encode(input)
        assert.equals(input, b64url.decode(encoded))
    end)

    it('round-trips all byte values', function()
        local bytes = {}
        for i = 0, 255 do bytes[#bytes + 1] = string.char(i) end
        local input = table.concat(bytes)
        assert.equals(input, b64url.decode(b64url.encode(input)))
    end)
end)

describe('quality review: tools', function()
    it('unpack_inline_message_id returns the real access_hash', function()
        -- the '<iiI' format had only 3 items, so access_hash always
        -- received string.unpack's next-position return (13).
        local packed = string.pack('<i4i4i4i8', 4, 100, 200, 1234567890123)
        local r = tools.unpack_inline_message_id(b64url.encode(packed))
        assert.equals(4, r.dc_id)
        assert.equals(100, r.message_id)
        assert.equals(200, r.chat_id)
        assert.equals(1234567890123, r.access_hash)
    end)

    it('unpack functions return false on undecodable input', function()
        local ok, err = tools.unpack_telegram_invite_link('++%%')
        assert.is_false(ok)
        assert.equals('Could not decode!', err)
        ok, err = tools.unpack_file_id('++%%')
        assert.is_false(ok)
        assert.equals('Could not decode!', err)
        ok, err = tools.unpack_inline_message_id('++%%')
        assert.is_false(ok)
        assert.equals('Could not decode!', err)
    end)

    it('unpack functions return false on truncated payloads instead of raising', function()
        local ok = tools.unpack_inline_message_id(b64url.encode('xy'))
        assert.is_false(ok)
        ok = tools.unpack_file_id(b64url.encode('xy'))
        assert.is_false(ok)
        ok = tools.unpack_telegram_invite_link(b64url.encode('xy'))
        assert.is_false(ok)
    end)

    it('random_string returns empty string for non-numeric length', function()
        assert.equals('', tools.random_string('abc'))
    end)

    it('rle_encode/rle_decode round-trip trailing NUL runs', function()
        local input = 'a\0\0\0'
        assert.equals(input, tools.rle_decode(tools.rle_encode(input)))
        assert.equals('\0\0', tools.rle_decode(tools.rle_encode('\0\0')))
    end)

    it('file_size works with relative paths that exist', function()
        assert.is_true(tools.file_exists('src/config.lua'))
        local size = tools.file_size('src/config.lua')
        assert.is_number(size)
        assert.is_true(size > 0)
    end)

    it('table_random picks uniformly from plain arrays without crashing', function()
        local pick = tools.table_random({ 'a', 'b', 'c' })
        assert.is_true(pick == 'a' or pick == 'b' or pick == 'c')
    end)

    it('table_random handles scalar input via its documented fallback', function()
        assert.equals('x', tools.table_random('x'))
    end)

    it('table_random still honours weighted maps', function()
        local pick = tools.table_random({ heads = 0, tails = 1 })
        assert.equals('tails', pick)
    end)
end)
