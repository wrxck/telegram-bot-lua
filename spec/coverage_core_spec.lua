-- coverage-focused tests for the core modules: builders, utils, helpers,
-- middleware, framework and handlers. exercises the branches not reached by
-- the existing specs (encoded button forms, markdown fmt variants, debug
-- logging in the sync poll loop, and framework fall-through paths).
local api = require('spec.test_helper')
local json = require('dkjson')

describe('builders coverage', function()
    describe('row builder', function()
        it('supports switch_inline_query_current_chat_button', function()
            local r = api.row():switch_inline_query_current_chat_button('Search here', 'cats')
            assert.equals('Search here', r[1].text)
            assert.equals('cats', r[1].switch_inline_query_current_chat)
        end)
    end)

    describe('standalone buttons', function()
        it('callback_data_button returns false for missing params and encodes on request', function()
            assert.is_false(api.callback_data_button(nil, 'data'))
            assert.is_false(api.callback_data_button('text', nil))
            local encoded = api.callback_data_button('Press', 'do:it', true)
            assert.is_string(encoded)
            local decoded = json.decode(encoded)
            assert.equals('Press', decoded.text)
            assert.equals('do:it', decoded.callback_data)
        end)

        it('switch_inline_query_button builds, validates and encodes', function()
            assert.is_false(api.switch_inline_query_button(nil, 'q'))
            assert.is_false(api.switch_inline_query_button('text', nil))
            local button = api.switch_inline_query_button('Share', 'query')
            assert.equals('Share', button.text)
            assert.equals('query', button.switch_inline_query)
            local decoded = json.decode(api.switch_inline_query_button('Share', 'query', true))
            assert.equals('query', decoded.switch_inline_query)
        end)

        it('switch_inline_query_current_chat_button builds, validates and encodes', function()
            assert.is_false(api.switch_inline_query_current_chat_button(nil, 'q'))
            assert.is_false(api.switch_inline_query_current_chat_button('text', nil))
            local button = api.switch_inline_query_current_chat_button('Here', 'dogs')
            assert.equals('Here', button.text)
            assert.equals('dogs', button.switch_inline_query_current_chat)
            local decoded = json.decode(api.switch_inline_query_current_chat_button('Here', 'dogs', true))
            assert.equals('dogs', decoded.switch_inline_query_current_chat)
        end)

        it('callback_game_button returns false for missing params and encodes on request', function()
            assert.is_false(api.callback_game_button(nil, 'game'))
            assert.is_false(api.callback_game_button('text', nil))
            local decoded = json.decode(api.callback_game_button('Play', 'my_game', true))
            assert.equals('Play', decoded.text)
            assert.equals('my_game', decoded.callback_game)
        end)

        it('pay_button builds, validates and encodes', function()
            assert.is_false(api.pay_button(nil, true))
            assert.is_false(api.pay_button('text', nil))
            local button = api.pay_button('Buy now', true)
            assert.equals('Buy now', button.text)
            assert.is_true(button.pay)
            local decoded = json.decode(api.pay_button('Buy now', true, true))
            assert.is_true(decoded.pay)
        end)
    end)

    describe('shipping options builder', function()
        it('chains shipping options with stringified id and title', function()
            local prices = api.prices():labeled_price('Postage', 500)
            local options = api.shipping_options()
                :shipping_option(1, 'Standard', prices)
                :shipping_option('express', 'Express', prices)
            assert.equals(2, #options)
            assert.equals('1', options[1].id)
            assert.equals('Standard', options[1].title)
            assert.equals(prices, options[1].prices)
            assert.equals('express', options[2].id)
        end)
    end)

    describe('labeled_price encoding', function()
        it('json-encodes the price when requested', function()
            local decoded = json.decode(api.labeled_price('Total', '250', true))
            assert.equals('Total', decoded.label)
            assert.equals(250, decoded.amount)
        end)
    end)

    describe('mask position builder', function()
        it('chains positions with numeric coercion', function()
            local mask = api.mask_position():position('eyes', '0.5', '-0.5', '2')
            assert.equals(1, #mask)
            assert.equals('eyes', mask[1].point)
            assert.equals(0.5, mask[1].x_shift)
            assert.equals(-0.5, mask[1].y_shift)
            assert.equals(2, mask[1].scale)
        end)
    end)

    describe('input media constructors', function()
        it('input_media_photo splits object and file reference', function()
            local obj, files = api.input_media_photo('photo.jpg', 'cap', 'HTML')
            assert.equals('photo', obj.type)
            assert.equals('cap', obj.caption)
            assert.equals('HTML', obj.parse_mode)
            assert.equals('photo.jpg', files.media)
        end)

        it('input_media_video coerces dimensions and keeps the thumbnail', function()
            local obj, files = api.input_media_video('vid.mp4', 'thumb.jpg', 'cap', 'HTML', '640', '480', '30', true)
            assert.equals('video', obj.type)
            assert.equals(640, obj.width)
            assert.equals(480, obj.height)
            assert.equals(30, obj.duration)
            assert.is_true(obj.supports_streaming)
            assert.equals('vid.mp4', files.media)
            assert.equals('thumb.jpg', files.thumbnail)
        end)

        it('input_media_animation coerces dimensions', function()
            local obj, files = api.input_media_animation('anim.gif', 'thumb.jpg', 'cap', 'HTML', '320', '240', '5')
            assert.equals('animation', obj.type)
            assert.equals(320, obj.width)
            assert.equals(240, obj.height)
            assert.equals(5, obj.duration)
            assert.equals('anim.gif', files.media)
        end)

        it('input_media_audio carries performer and title', function()
            local obj, files = api.input_media_audio('song.mp3', 'thumb.jpg', 'cap', 'HTML', '180', 'Artist', 'Song')
            assert.equals('audio', obj.type)
            assert.equals(180, obj.duration)
            assert.equals('Artist', obj.performer)
            assert.equals('Song', obj.title)
            assert.equals('song.mp3', files.media)
        end)

        it('input_media_document splits object and files', function()
            local obj, files = api.input_media_document('doc.pdf', 'thumb.jpg', 'cap', 'HTML')
            assert.equals('document', obj.type)
            assert.equals('cap', obj.caption)
            assert.equals('doc.pdf', files.media)
            assert.equals('thumb.jpg', files.thumbnail)
        end)

        it('input_media():photo chains and stringifies the media', function()
            local media = api.input_media():photo(12345, 'first'):photo('id2')
            assert.equals(2, #media)
            assert.equals('photo', media[1].type)
            assert.equals('12345', media[1].media)
            assert.equals('first', media[1].caption)
            assert.equals('id2', media[2].media)
        end)
    end)

    describe('input message content constructors', function()
        it('input_location_message_content coerces coordinates and encodes', function()
            local content = api.input_location_message_content('1.5', '2.5')
            assert.equals(1.5, content.latitude)
            assert.equals(2.5, content.longitude)
            local decoded = json.decode(api.input_location_message_content(1, 2, true))
            assert.equals(1, decoded.latitude)
            assert.equals(2, decoded.longitude)
        end)

        it('input_venue_message_content stringifies title and address', function()
            local content = api.input_venue_message_content(1, 2, 99, 100, 'fsq')
            assert.equals('99', content.title)
            assert.equals('100', content.address)
            assert.equals('fsq', content.foursquare_id)
            local decoded = json.decode(api.input_venue_message_content(1, 2, 'T', 'A', nil, true))
            assert.equals('T', decoded.title)
        end)

        it('input_contact_message_content keeps last_name optional', function()
            local content = api.input_contact_message_content('+441234', 'Matt')
            assert.equals('+441234', content.phone_number)
            assert.equals('Matt', content.first_name)
            assert.is_nil(content.last_name)
            local decoded = json.decode(api.input_contact_message_content('+441234', 'Matt', 'H', true))
            assert.equals('H', decoded.last_name)
        end)
    end)

    describe('inline_result hide_url', function()
        it('defaults nil to false and keeps true', function()
            assert.is_false(api.inline_result():hide_url(nil).hide_url)
            assert.is_true(api.inline_result():hide_url(true).hide_url)
        end)
    end)

    describe('bot command scopes', function()
        it('builds every scope with its discriminator', function()
            assert.same({ type = 'default' }, api.bot_command_scope_default())
            assert.same({ type = 'all_private_chats' }, api.bot_command_scope_all_private_chats())
            assert.same({ type = 'all_group_chats' }, api.bot_command_scope_all_group_chats())
            assert.same({ type = 'all_chat_administrators' }, api.bot_command_scope_all_chat_administrators())
            assert.same({ type = 'chat', chat_id = 5 }, api.bot_command_scope_chat(5))
            assert.same({ type = 'chat_administrators', chat_id = 5 }, api.bot_command_scope_chat_administrators(5))
            assert.same({ type = 'chat_member', chat_id = 5, user_id = 6 }, api.bot_command_scope_chat_member(5, 6))
        end)
    end)

    describe('menu buttons', function()
        it('builds commands, web_app and default menu buttons', function()
            assert.same({ type = 'commands' }, api.menu_button_commands())
            local web_app = { url = 'https://example.com' }
            assert.same({ type = 'web_app', text = 'Open', web_app = web_app },
                api.menu_button_web_app('Open', web_app))
            assert.same({ type = 'default' }, api.menu_button_default())
        end)
    end)

    describe('link_preview_options', function()
        it('carries all five fields', function()
            local opts = api.link_preview_options(true, 'https://example.com', true, false, true)
            assert.is_true(opts.is_disabled)
            assert.equals('https://example.com', opts.url)
            assert.is_true(opts.prefer_small_media)
            assert.is_false(opts.prefer_large_media)
            assert.is_true(opts.show_above_text)
        end)
    end)

    describe('input_sticker', function()
        it('carries sticker, emoji list, mask position and keywords', function()
            local sticker = api.input_sticker('file_id', { 'X' }, { point = 'eyes' }, { 'kw' })
            assert.equals('file_id', sticker.sticker)
            assert.same({ 'X' }, sticker.emoji_list)
            assert.equals('eyes', sticker.mask_position.point)
            assert.same({ 'kw' }, sticker.keywords)
        end)
    end)

    describe('inline_query_results_button', function()
        it('carries text, web_app and start_parameter', function()
            local button = api.inline_query_results_button('More', { url = 'https://x' }, 'deep')
            assert.equals('More', button.text)
            assert.equals('https://x', button.web_app.url)
            assert.equals('deep', button.start_parameter)
        end)
    end)

    describe('passport element errors', function()
        it('builds each remaining error source with its fields', function()
            local single_hash = {
                { api.passport_element_error_reverse_side, 'reverse_side' },
                { api.passport_element_error_selfie, 'selfie' },
                { api.passport_element_error_file, 'file' },
                { api.passport_element_error_translation_file, 'translation_file' }
            }
            for _, case in ipairs(single_hash) do
                local err = case[1]('passport', 'hash1', 'Bad scan')
                assert.equals(case[2], err.source)
                assert.equals('passport', err.type)
                assert.equals('hash1', err.file_hash)
                assert.equals('Bad scan', err.message)
            end
            local multi_hash = {
                { api.passport_element_error_files, 'files' },
                { api.passport_element_error_translation_files, 'translation_files' }
            }
            for _, case in ipairs(multi_hash) do
                local err = case[1]('utility_bill', { 'h1', 'h2' }, 'Bad set')
                assert.equals(case[2], err.source)
                assert.same({ 'h1', 'h2' }, err.file_hashes)
                assert.equals('Bad set', err.message)
            end
        end)
    end)
end)

describe('utils coverage', function()
    describe('fmt markdown variants', function()
        it('bold falls back to legacy markdown', function()
            assert.equals('*a\\_b*', api.fmt.bold('a_b', 'Markdown'))
        end)

        it('italic supports MarkdownV2 and legacy markdown', function()
            assert.equals('_a\\.b_', api.fmt.italic('a.b', 'MarkdownV2'))
            assert.equals('_a\\_b_', api.fmt.italic('a_b', 'Markdown'))
        end)

        it('pre without a language wraps in a bare pre tag', function()
            assert.equals('<pre>x &lt; y</pre>', api.fmt.pre('x < y'))
        end)

        it('mention defaults to an HTML deep link', function()
            assert.equals('<a href="tg://user?id=7">Bob</a>', api.fmt.mention(7, 'Bob'))
        end)

        it('strikethrough and underline escape MarkdownV2', function()
            assert.equals('~a\\.b~', api.fmt.strikethrough('a.b', 'MarkdownV2'))
            assert.equals('__a\\.b__', api.fmt.underline('a.b', 'MarkdownV2'))
        end)
    end)

    describe('id extraction fall-throughs', function()
        it('get_user_id returns nil when no from can be found', function()
            assert.is_nil(api.get_user_id({}))
            assert.is_nil(api.get_user_id({ message = {} }))
        end)

        it('get_chat_id returns nil for non-tables and chatless updates', function()
            assert.is_nil(api.get_chat_id('not a table'))
            assert.is_nil(api.get_chat_id({ message = {} }))
        end)
    end)

    describe('predicate guards', function()
        it('is_reply, is_private and is_group reject non-table input', function()
            assert.is_false(api.is_reply('nope'))
            assert.is_false(api.is_private(42))
            assert.is_false(api.is_group(nil))
        end)
    end)

    describe('decode_callback', function()
        it('returns nil for an empty string', function()
            assert.is_nil(api.decode_callback(''))
        end)
    end)
end)

describe('helpers coverage', function()
    before_each(function()
        api._clear_requests()
    end)

    it('status checks surface the http status when the response has no result', function()
        api._mock_response({ ok = false, error_code = 400, description = 'Bad Request' })
        local ok, res = api.is_user_kicked(123, 456)
        assert.is_false(ok)
        assert.equals(200, res)
    end)
end)

describe('middleware coverage', function()
    before_each(function()
        api._middleware = {}
        api._scoped_middleware = {}
    end)

    after_each(function()
        api._middleware = {}
        api._scoped_middleware = {}
    end)

    it('raises when next() is called multiple times', function()
        api.use(function(_, next)
            next()
            next()
        end)
        local ok, err = pcall(api.process_update, {
            update_id = 1,
            message = { chat = { id = 1, type = 'private' }, text = 'plain text' }
        })
        assert.is_false(ok)
        assert.truthy(tostring(err):find('next() called multiple times', 1, true))
    end)
end)

describe('framework coverage', function()
    local saved_on_message

    before_each(function()
        api._clear_requests()
        api._commands = {}
        api._hears = {}
        api._waiters = {}
        api._command_not_found = nil
        saved_on_message = api.on_message
        api.on_message = function() end
    end)

    after_each(function()
        api._commands = {}
        api._hears = {}
        api._waiters = {}
        api._command_not_found = nil
        api.on_message = saved_on_message
    end)

    it('ctx.reply_with_photo sends a photo to the context chat', function()
        local ctx = api.build_context({
            update_id = 1,
            message = { chat = { id = 321, type = 'private' }, from = { id = 9 }, text = 'hi' }
        })
        ctx.reply_with_photo('photo_file_id', { caption = 'look' })
        local req = api._last_request()
        assert.truthy(req.endpoint:find('/sendPhoto', 1, true))
        assert.equals(321, req.parameters.chat_id)
        assert.equals('look', req.parameters.caption)
    end)

    it('_framework_handle ignores updates without a message or callback_query', function()
        local ran = false
        api.command('start', function() ran = true end)
        assert.is_false(api._framework_handle({ poll = { id = 'p1' } }))
        assert.is_false(ran)
    end)

    it('_framework_handle returns false when no hears pattern matches', function()
        local ran = false
        api.hears('^exact$', function() ran = true end)
        api.hears(function(text) return text == 'magic word' and text or nil end,
            function() ran = true end)
        local handled = api._framework_handle({
            update_id = 2,
            message = { chat = { id = 1, type = 'private' }, from = { id = 2 }, text = 'something else' }
        })
        assert.is_false(handled)
        assert.is_false(ran)
    end)
end)

describe('handlers sync loop debug output', function()
    local original_get_updates
    local original_on_message
    local original_debug
    local original_print
    local printed

    before_each(function()
        original_get_updates = api.get_updates
        original_on_message = api.on_message
        original_debug = api.debug
        original_print = _G.print
        printed = {}
        api.debug = true
        _G.print = function(...)
            table.insert(printed, table.concat({ ... }, '\t'))
        end
    end)

    after_each(function()
        api.get_updates = original_get_updates
        api.on_message = original_on_message
        api.debug = original_debug
        _G.print = original_print
        api._sync_running = false
    end)

    local function null_sleeper() end

    it('logs polling errors with the backoff delay when debug is on', function()
        local calls = 0
        api.get_updates = function()
            calls = calls + 1
            if calls == 1 then
                error('boom transport')
            end
            api.stop_sync()
            return { ok = true, result = {} }, 200
        end
        api._run_sync({ _sleeper = null_sleeper })
        assert.equals(2, calls)
        local found = false
        for _, line in ipairs(printed) do
            if line:find('Polling error [', 1, true) and line:find('boom transport', 1, true)
                and line:find('backing off 1s', 1, true) then
                found = true
            end
        end
        assert.is_true(found)
    end)

    it('logs handler errors without killing the loop when debug is on', function()
        api.on_message = function() error('handler exploded') end
        local calls = 0
        api.get_updates = function()
            calls = calls + 1
            if calls == 1 then
                return { ok = true, result = {
                    { update_id = 7, message = { chat = { type = 'private' }, text = 'x' } }
                } }, 200
            end
            api.stop_sync()
            return { ok = true, result = {} }, 200
        end
        api._run_sync({ _sleeper = null_sleeper })
        assert.equals(2, calls)
        local found = false
        for _, line in ipairs(printed) do
            if line:find('Update handler error:', 1, true) and line:find('handler exploded', 1, true) then
                found = true
            end
        end
        assert.is_true(found)
    end)

    it('logs empty poll results with the backoff delay when debug is on', function()
        local calls = 0
        api.get_updates = function()
            calls = calls + 1
            if calls == 1 then
                return false, 'connection refused'
            end
            api.stop_sync()
            return { ok = true, result = {} }, 200
        end
        api._run_sync({ _sleeper = null_sleeper })
        assert.equals(2, calls)
        local found = false
        for _, line in ipairs(printed) do
            if line:find('Polling returned no result, backing off 1s', 1, true) then
                found = true
            end
        end
        assert.is_true(found)
    end)
end)
