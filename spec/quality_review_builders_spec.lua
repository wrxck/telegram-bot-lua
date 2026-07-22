-- regression tests for builder issues found during the quality review.
local api = require('spec.test_helper')
local json = require('dkjson')

describe('quality review: builders', function()
    describe('message_entity', function()
        it('omits nil optional fields instead of the string "nil"', function()
            local e = api.message_entity('bold', 0, 4)
            assert.equals('bold', e.type)
            assert.equals(0, e.offset)
            assert.equals(4, e.length)
            assert.is_nil(e.url)
            assert.is_nil(e.language)
            assert.is_nil(e.custom_emoji_id)
        end)

        it('keeps provided optional fields', function()
            local e = api.message_entity('text_link', 0, 4, 'https://x.example', nil, 'lua', 'emoji1')
            assert.equals('https://x.example', e.url)
            assert.equals('lua', e.language)
            assert.equals('emoji1', e.custom_emoji_id)
        end)
    end)

    describe('reply_parameters', function()
        it('leaves quote_entities as a table so it is not double-encoded', function()
            -- consumers json.encode the whole reply_parameters table; a
            -- pre-encoded string here became a JSON-string-in-JSON.
            local rp = api.reply_parameters(42, 123, true, 'q', 'HTML',
                { { type = 'bold', offset = 0, length = 4 } })
            assert.is_table(rp.quote_entities)
            local wire = json.decode(json.encode(rp))
            assert.is_table(wire.quote_entities)
            assert.equals('bold', wire.quote_entities[1].type)
        end)
    end)

    describe('callback_game_button', function()
        it('preserves a CallbackGame table instead of stringifying it', function()
            local b = api.callback_game_button('play', {})
            assert.is_table(b.callback_game)
            assert.truthy(json.encode(b):find('"callback_game":{}', 1, true))
        end)

        it('still accepts the documented string form', function()
            local b = api.callback_game_button('play', 'game')
            assert.equals('game', b.callback_game)
        end)
    end)

    describe('all-optional object builders encode as JSON objects, not arrays', function()
        it('chat_permissions() with defaults', function()
            assert.equals('{}', json.encode(api.chat_permissions()))
        end)

        it('chat_administrator_rights() with defaults', function()
            assert.equals('{}', json.encode(api.chat_administrator_rights()))
        end)

        it('accepted_gift_types() with defaults', function()
            assert.equals('{}', json.encode(api.accepted_gift_types()))
        end)

        it('suggested_post_parameters() with defaults', function()
            assert.equals('{}', json.encode(api.suggested_post_parameters()))
        end)

        it('keyboard_button_request_poll without a poll type', function()
            local b = api.keyboard_button_request_poll('t')
            assert.truthy(json.encode(b):find('"request_poll":{}', 1, true))
        end)

        it('input_rich_message() with defaults', function()
            assert.equals('{}', json.encode(api.input_rich_message()))
        end)

        it('populated builders still encode their fields', function()
            local p = api.chat_permissions({ can_send_messages = true })
            assert.equals('{"can_send_messages":true}', json.encode(p))
        end)
    end)

    describe('input_media builder coercion consistency', function()
        it('input_media():video coerces dimensions like the standalone builder', function()
            local media = api.input_media():video('fid', 'cap', '640', '480', '10')
            assert.equals(640, media[1].width)
            assert.equals(480, media[1].height)
            assert.equals(10, media[1].duration)
        end)
    end)

    describe('helpers error propagation', function()
        local original
        before_each(function()
            original = api.get_chat_member
        end)
        after_each(function()
            api.get_chat_member = original
        end)

        it('get_chat_member_permissions preserves the error like its siblings', function()
            local err_payload = { ok = false, error_code = 400, description = 'boom' }
            api.get_chat_member = function()
                return false, err_payload
            end
            local ok, err = api.get_chat_member_permissions(1, 2)
            assert.is_false(ok)
            assert.equals(err_payload, err)
        end)
    end)
end)
