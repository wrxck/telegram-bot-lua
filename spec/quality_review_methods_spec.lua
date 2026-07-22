-- regression tests for methods-layer issues found during the quality review.
local api = require('spec.test_helper')
local config = require('telegram-bot-lua.config')

describe('quality review: methods layer', function()
    before_each(function()
        api._clear_requests()
    end)

    describe('get_updates honours config.endpoint', function()
        local original_endpoint
        before_each(function()
            original_endpoint = config.endpoint
        end)
        after_each(function()
            config.endpoint = original_endpoint
        end)

        it('uses config.endpoint like every other method', function()
            config.endpoint = 'https://local-bot-api:8081/bot'
            api.get_updates({ timeout = 1 })
            local req = api._last_request()
            assert.equals('https://local-bot-api:8081/bottest:TOKEN/getUpdates', req.endpoint)
        end)

        it('inserts beta/ before the bot path segment for the beta endpoint', function()
            api.get_updates({ timeout = 1, use_beta_endpoint = true })
            local req = api._last_request()
            assert.equals('https://api.telegram.org/beta/bottest:TOKEN/getUpdates', req.endpoint)
        end)

        it('defaults to the standard endpoint', function()
            api.get_updates({ timeout = 1 })
            local req = api._last_request()
            assert.equals('https://api.telegram.org/bottest:TOKEN/getUpdates', req.endpoint)
        end)
    end)

    describe('truncating setters no longer fabricate the string "nil"', function()
        it('set_chat_description omits a nil description', function()
            api.set_chat_description(123)
            assert.is_nil(api._last_request().parameters.description)
        end)

        it('set_my_name omits a nil name', function()
            api.set_my_name(nil)
            assert.is_nil(api._last_request().parameters.name)
        end)

        it('set_chat_title still truncates over-long titles', function()
            api.set_chat_title(123, string.rep('x', 200))
            assert.equals(128, #api._last_request().parameters.title)
        end)

        it('set_chat_administrator_custom_title still truncates to 16', function()
            api.set_chat_administrator_custom_title(1, 2, string.rep('t', 30))
            assert.equals(16, #api._last_request().parameters.custom_title)
        end)

        it('_truncate keeps short values unchanged', function()
            assert.equals('abc', api._truncate('abc', 10))
            assert.equals('5', api._truncate(5, 10))
        end)
    end)

    describe('parse_mode = false is omitted, not stringified', function()
        it('send_message drops parse_mode=false', function()
            api.send_message(123, 'hi', { parse_mode = false })
            assert.is_nil(api._last_request().parameters.parse_mode)
        end)

        it('send_message still maps parse_mode=true to MarkdownV2', function()
            api.send_message(123, 'hi', { parse_mode = true })
            assert.equals('MarkdownV2', api._last_request().parameters.parse_mode)
        end)

        it('edit_message_caption drops parse_mode=false', function()
            api.edit_message_caption(123, 456, 'cap', { parse_mode = false })
            assert.is_nil(api._last_request().parameters.parse_mode)
        end)

        it('input_text_message_content drops parse_mode=false', function()
            local content = api.input_text_message_content('hi', false)
            assert.is_nil(content.parse_mode)
        end)
    end)

    describe('send_reply delegates to send_message', function()
        local message = { chat = { id = 77 }, message_id = 5 }

        it('supports every send_message option (no drift)', function()
            api.send_reply(message, 'hi', {
                business_connection_id = 'biz',
                message_effect_id = 'fx',
                allow_paid_broadcast = true
            })
            local p = api._last_request().parameters
            assert.equals('biz', p.business_connection_id)
            assert.equals('fx', p.message_effect_id)
            assert.is_true(p.allow_paid_broadcast)
        end)

        it('injects reply_parameters from the message', function()
            api.send_reply(message, 'hi')
            local p = api._last_request().parameters
            local rp = require('dkjson').decode(p.reply_parameters)
            assert.equals(5, rp.message_id)
            assert.equals(77, rp.chat_id)
            assert.is_true(rp.allow_sending_without_reply)
        end)

        it('does not mutate the caller opts table', function()
            local opts = { disable_notification = true }
            api.send_reply(message, 'hi', opts)
            assert.is_nil(opts.reply_parameters)
        end)

        it('still returns false for invalid message objects', function()
            assert.is_false(api.send_reply(nil, 'hi'))
            assert.is_false(api.send_reply({}, 'hi'))
        end)
    end)

    describe('compat v2 send_message shorthand', function()
        it('forwards only position 4 after parse_mode as reply_markup', function()
            -- positions: parse_mode, disable_web_page_preview,
            -- disable_notification, reply_to_message_id, reply_markup
            local markup = { inline_keyboard = {} }
            api.send_message(1, 'hi', 'HTML', nil, nil, nil, markup)
            local p = api._last_request().parameters
            assert.truthy(p.reply_markup)
        end)

        it('does not forward later positionals as reply_markup', function()
            api.send_message(1, 'hi', 'HTML', nil, nil, nil, nil, { entities_like = true })
            local p = api._last_request().parameters
            assert.is_nil(p.reply_markup)
        end)
    end)
end)
