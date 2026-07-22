-- coverage-focused tests for src/tools.lua and src/b64url.lua: exercises the
-- branches not reached by the existing specs (network download paths, binary
-- unpackers, hexdump, and the remaining service/media discriminators).
local api = require('spec.test_helper')
local tools = require('telegram-bot-lua.tools')
local b64url = require('telegram-bot-lua.b64url')
local https = require('ssl.https')
local http = require('socket.http')

describe('tools coverage', function()
    describe('get_linked_name', function()
        local original_get_chat

        before_each(function()
            original_get_chat = api.get_chat
        end)

        after_each(function()
            api.get_chat = original_get_chat
        end)

        it('returns false when get_chat fails', function()
            api.get_chat = function() return false, 404 end
            assert.is_false(tools.get_linked_name(123))
        end)

        it('returns false when the response has no result', function()
            api.get_chat = function() return { ok = false }, 200 end
            assert.is_false(tools.get_linked_name(123))
        end)

        it('returns the escaped first name when there is no username', function()
            api.get_chat = function()
                return { ok = true, result = { first_name = 'Bob <3' } }, 200
            end
            assert.equals('Bob &lt;3', tools.get_linked_name(123))
        end)

        it('returns an HTML link when the user has a username', function()
            api.get_chat = function()
                return { ok = true, result = { first_name = 'Bob', username = 'bob_bot' } }, 200
            end
            assert.equals('<a href="https://t.me/bob_bot">Bob</a>', tools.get_linked_name(123))
        end)
    end)

    describe('download_file', function()
        local original_https_request = https.request
        local original_http_request = http.request
        local requested_urls

        local function fake_request(payload, status)
            return function(opts)
                table.insert(requested_urls, opts.url)
                if payload then
                    opts.sink(payload)
                end
                opts.sink(nil)
                return 1, status
            end
        end

        before_each(function()
            requested_urls = {}
        end)

        after_each(function()
            https.request = original_https_request
            http.request = original_http_request
        end)

        it('downloads over https, deriving the name from the url extension', function()
            https.request = fake_request('secure-bytes', 200)
            local path = tools.download_file('https://example.com/image.jpg')
            assert.is_string(path)
            assert.truthy(path:match('^/tmp/%d+%.jpg$'))
            assert.equals('https://example.com/image.jpg', requested_urls[1])
            assert.equals('secure-bytes', tools.read_file(path))
            os.remove(path)
        end)

        it('downloads over plain http with an explicit name and relative path', function()
            http.request = fake_request('plain-bytes', 200)
            -- a relative path is anchored under /tmp/ and given a trailing slash
            local path = tools.download_file('http://example.com/file', 'cov_dl.bin', '.')
            assert.equals('/tmp/./cov_dl.bin', path)
            assert.equals('plain-bytes', tools.read_file(path))
            os.remove(path)
        end)

        it('appends a trailing slash to absolute directory paths', function()
            https.request = fake_request('abs-bytes', 200)
            local path = tools.download_file('https://example.com/x.bin', 'cov_abs.bin', '/tmp')
            assert.equals('/tmp/cov_abs.bin', path)
            assert.equals('abs-bytes', tools.read_file(path))
            os.remove(path)
        end)

        it('returns false and the status code on a non-200 response', function()
            https.request = fake_request(nil, 404)
            local ok, err = tools.download_file('https://example.com/missing.png')
            assert.is_false(ok)
            assert.equals(404, err)
        end)

        it('returns false when the target file cannot be opened', function()
            https.request = fake_request('data', 200)
            local ok, err = tools.download_file('https://example.com/y.bin', 'y.bin', '/nonexistent_cov_dir/sub')
            assert.is_false(ok)
            assert.equals('Could not open file for writing', err)
        end)
    end)

    describe('save_to_file edge cases', function()
        it('returns false when data or filename is missing', function()
            assert.is_false(tools.save_to_file(nil, 'x.txt'))
            assert.is_false(tools.save_to_file('data', nil))
        end)

        it('returns false when the file cannot be opened', function()
            -- an empty filename resolves to the /tmp directory itself
            assert.is_false(tools.save_to_file('data', ''))
        end)
    end)

    describe('file read fallbacks', function()
        it('get_file_as_table returns an empty table for missing files', function()
            assert.same({}, tools.get_file_as_table('/nonexistent_cov/file.txt'))
            assert.same({}, tools.get_file_as_table(nil))
        end)

        it('read_file returns false for an unopenable path', function()
            assert.is_false(tools.read_file('/nonexistent_cov/file.txt'))
        end)

        it('json_to_table returns an empty table for nil or missing paths', function()
            assert.same({}, tools.json_to_table(nil))
            assert.same({}, tools.json_to_table('/nonexistent_cov/file.json'))
        end)
    end)

    describe('get_formatted_user legacy markdown', function()
        it('escapes markdown v1 characters in the name', function()
            assert.equals('[a\\_b](tg://user?id=42)', tools.get_formatted_user(42, 'a_b', 'Markdown'))
        end)
    end)

    describe('string_hexdump', function()
        it('dumps bytes as hex with default options', function()
            assert.equals('414243', tools.string_hexdump('ABC'))
        end)

        it('honours size, space and length options', function()
            -- size 2 reverses byte pairs, space groups every 2 columns,
            -- length 4 breaks lines every 4 bytes
            assert.equals('42414443 \n46454847 \n', tools.string_hexdump('ABCDEFGH', 4, 2, 2))
        end)

        it('coerces invalid options back to their defaults', function()
            assert.equals(tools.string_hexdump('AB'), tools.string_hexdump('AB', 'x', -1, 0))
        end)
    end)

    describe('table_random with a seed', function()
        it('is deterministic for the same seed', function()
            local first = tools.table_random({ heads = 1, tails = 1 }, 42)
            local second = tools.table_random({ heads = 1, tails = 1 }, 42)
            assert.truthy(first == 'heads' or first == 'tails')
            assert.equals(first, second)
        end)
    end)

    describe('service_message discriminators', function()
        it('reports every service field with its own reason', function()
            local fields = {
                'left_chat_member', 'new_chat_title', 'new_chat_photo',
                'delete_chat_photo', 'group_chat_created', 'supergroup_chat_created',
                'channel_chat_created', 'migrate_to_chat_id', 'migrate_from_chat_id',
                'pinned_message', 'successful_payment', 'forum_topic_edited',
                'forum_topic_closed', 'forum_topic_reopened',
                'general_forum_topic_hidden', 'general_forum_topic_unhidden',
                'video_chat_scheduled', 'video_chat_started', 'video_chat_ended',
                'video_chat_participants_invited', 'web_app_data',
                'write_access_allowed', 'proximity_alert_triggered', 'users_shared',
                'chat_shared', 'giveaway_winners', 'giveaway_completed',
                'boost_added', 'chat_background_set', 'paid_media_purchased'
            }
            for _, field in ipairs(fields) do
                local is, kind = tools.service_message({ [field] = {} })
                assert.is_true(is, field)
                assert.equals(field, kind)
            end
        end)
    end)

    describe('media_type remaining discriminators', function()
        it('maps each media field to its type string', function()
            assert.equals('document', tools.media_type({ document = {} }))
            assert.equals('game', tools.media_type({ game = {} }))
            assert.equals('voice', tools.media_type({ voice = {} }))
            assert.equals('video note', tools.media_type({ video_note = {} }))
            assert.equals('contact', tools.media_type({ contact = {} }))
            assert.equals('location', tools.media_type({ location = {} }))
            assert.equals('venue', tools.media_type({ venue = {} }))
            assert.equals('invoice', tools.media_type({ invoice = {} }))
            assert.equals('dice', tools.media_type({ dice = {} }))
            assert.equals('poll', tools.media_type({ poll = {} }))
        end)

        it('labels forwarded messages', function()
            assert.equals('forwarded', tools.media_type({ forward_from = { id = 1 } }))
            assert.equals('forwarded', tools.media_type({ forward_from_chat = { id = 1 } }))
        end)
    end)

    describe('file_id remaining media kinds', function()
        it('extracts plain and unique ids for every media kind', function()
            local kinds = { 'document', 'sticker', 'video', 'voice', 'animation', 'video_note' }
            for _, kind in ipairs(kinds) do
                local message = { [kind] = { file_id = kind .. '_id', file_unique_id = kind .. '_uid' } }
                assert.equals(kind .. '_id', tools.file_id(message), kind)
                assert.equals(kind .. '_uid', tools.file_id(message, true), kind)
            end
        end)

        it('extracts the unique id of the largest photo', function()
            local message = { photo = {
                { file_id = 'small', file_unique_id = 'small_uid' },
                { file_id = 'large', file_unique_id = 'large_uid' }
            } }
            assert.equals('large_uid', tools.file_id(message, true))
        end)
    end)

    describe('file_size with a trailing slash', function()
        it('strips the trailing slash before opening', function()
            local path = tools.save_to_file('12345', 'cov_size.txt')
            assert.equals(5, tools.file_size(path .. '/'))
            os.remove(path)
        end)
    end)

    describe('unpack_telegram_invite_link', function()
        it('returns false when no link is given', function()
            local ok, err = tools.unpack_telegram_invite_link(nil)
            assert.is_false(ok)
            assert.equals('No link given!', err)
        end)

        it('unpacks a joinchat url into its id fields', function()
            local payload = string.pack('>I4I4I8', 123, 456, 789)
            local link = 'https://t.me/joinchat/' .. b64url.encode(payload)
            local unpacked = tools.unpack_telegram_invite_link(link)
            assert.equals(123, unpacked.user_id)
            assert.equals(456, unpacked.chat_id)
            assert.equals(789, unpacked.rand_long)
        end)
    end)

    describe('unpack_file_id', function()
        -- construct synthetic telegram file_ids: a binary payload, run-length
        -- encoded, then base64url encoded (the inverse of what the parser does).
        local function make_file_id(payload)
            return b64url.encode(tools.rle_encode(payload))
        end

        it('returns false when no file_id is given', function()
            local ok, err = tools.unpack_file_id(nil)
            assert.is_false(ok)
            assert.equals('No file_id given!', err)
        end)

        it('parses a generic payload without a file reference', function()
            local payload = string.pack('<b', 8) .. '\0\0\0' .. string.pack('<i4', 4)
                .. string.pack('<i8i8', 111, 222) .. string.char(2)
            local result = tools.unpack_file_id(make_file_id(payload))
            assert.equals(8, result.file_type)
            assert.equals(4, result.dc_id)
            assert.equals(0, result.file_flags)
            assert.equals(2, result.version)
            assert.equals(0, result.subversion)
            assert.equals(222, result.access_hash)
            assert.equals('', result.media_type)
        end)

        it('parses photo payloads with the extended photo fields', function()
            local payload = string.pack('<b', 7) .. '\0\0\0' .. string.pack('<i4', 2)
                .. string.pack('<i8i8i8i8i4i4', 10, 20, 30, 40, 50, 60) .. string.char(4)
            local result = tools.unpack_file_id(make_file_id(payload), 'photo')
            assert.equals('photo', result.media_type)
            assert.equals(10, result.encrypted_user_id)
            assert.equals(20, result.access_hash)
            assert.equals(30, result.volume_id)
            assert.equals(40, result.secret)
            assert.equals(60, result.local_id)
            assert.equals(4, result.version)
        end)

        it('derives the sticker owner id from the high user_id bits', function()
            local payload = string.pack('<b', 3) .. '\0\0\0' .. string.pack('<i4', 1)
                .. string.pack('<i8i8', 5 * 2 ^ 32, 999) .. string.char(2)
            local result = tools.unpack_file_id(make_file_id(payload), 'sticker')
            assert.equals(5, result.user_id)
            assert.equals(999, result.access_hash)
        end)

        it('skips a short file reference when the flag bit is set', function()
            -- flags byte 4 = 0x02 sets bit 25 (the file reference flag);
            -- the reference is a 3-byte blob preceded by its length
            local payload = string.pack('<b', 9) .. '\0\0\2' .. string.pack('<i4', 3)
                .. string.char(3) .. 'RRR'
                .. string.pack('<i8i8', 77, 88) .. string.char(2)
            local result = tools.unpack_file_id(make_file_id(payload))
            assert.equals(0x2000000, result.file_flags)
            assert.equals(3, result.dc_id)
            assert.equals(88, result.access_hash)
        end)

        it('handles the long-form (254) file reference length marker', function()
            local payload = string.pack('<b', 9) .. '\0\0\2' .. string.pack('<i4', 3)
                .. string.char(254) .. '\0\0\0'
                .. string.pack('<i4', 0) .. string.pack('<i8', 555) .. string.char(2)
            local result = tools.unpack_file_id(make_file_id(payload))
            assert.equals(555, result.access_hash)
            assert.equals(2, result.version)
        end)
    end)

    describe('unpack_inline_message_id', function()
        it('returns false when no id is given', function()
            local ok, err = tools.unpack_inline_message_id(nil)
            assert.is_false(ok)
            assert.equals('No inline_message_id given!', err)
        end)
    end)
end)

describe('b64url coverage', function()
    it('rejects invalid characters in a 2-character tail', function()
        local out, err = b64url.decode('A!')
        assert.is_nil(out)
        assert.equals('invalid base64url character', err)
    end)

    it('rejects invalid characters in a 3-character tail', function()
        local out, err = b64url.decode('AA!')
        assert.is_nil(out)
        assert.equals('invalid base64url character', err)
    end)
end)
