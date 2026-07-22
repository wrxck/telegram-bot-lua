-- regression tests for issues found during the code quality review.
-- each describe block documents the defect it guards against.
local api = require('spec.test_helper')

describe('quality review regressions', function()
    describe('request layer never raises on malformed response bodies', function()
        local original
        before_each(function()
            original = require('ssl.https').request
        end)
        after_each(function()
            require('ssl.https').request = original
        end)

        it('returns a structured error for an empty response body', function()
            -- dkjson >= 2.8 raises on decode('') instead of returning nil;
            -- the request layer promises to always return (false, err).
            require('ssl.https').request = function() return 1, 200 end
            local ok, err = api._real_request('https://example.invalid/test', {})
            assert.is_false(ok)
            assert.is_table(err)
            assert.equals('failed to decode API response', err.description)
            assert.equals('', err.body)
        end)

        it('returns a structured error for a non-table JSON body', function()
            -- a body of 'true' decodes to a boolean; indexing jdat.ok raised.
            require('ssl.https').request = function(t)
                t.sink('true')
                return 1, 200
            end
            local ok, err = api._real_request('https://example.invalid/test', {})
            assert.is_false(ok)
            assert.is_table(err)
            assert.equals('failed to decode API response', err.description)
            assert.equals('true', err.body)
        end)
    end)

    describe('async request layer never raises on malformed response bodies', function()
        local copas_http = require('copas.http')
        local original
        before_each(function()
            original = copas_http.request
        end)
        after_each(function()
            copas_http.request = original
        end)

        it('returns a structured error for an empty response body', function()
            copas_http.request = function() return 1, 200 end
            local ok, err = api.async._http_request('https://example.invalid/test', {})
            assert.is_false(ok)
            assert.is_table(err)
            assert.equals('failed to decode API response', err.description)
        end)

        it('returns a structured error for a non-table JSON body', function()
            copas_http.request = function(t)
                t.sink('42')
                return 1, 200
            end
            local ok, err = api.async._http_request('https://example.invalid/test', {})
            assert.is_false(ok)
            assert.is_table(err)
            assert.equals('failed to decode API response', err.description)
        end)
    end)

    describe('webhook never raises on malformed bodies', function()
        it('process("") returns false, not an error', function()
            local ok, reason = api.webhook.process('')
            assert.is_false(ok)
            assert.equals('invalid update payload', reason)
        end)

        it('process(nil) returns false, not an error', function()
            local ok, reason = api.webhook.process(nil)
            assert.is_false(ok)
            assert.equals('invalid update payload', reason)
        end)

        it('process("true") returns false for non-table payloads', function()
            local ok, reason = api.webhook.process('true')
            assert.is_false(ok)
            assert.equals('invalid update payload', reason)
        end)

        it('_dispatch returns 400 for an empty POST body', function()
            local status, body = api.webhook._dispatch('POST', '/', {}, '', {})
            assert.equals(400, status)
            assert.equals('invalid payload', body)
        end)
    end)

    describe('update type detection is consistent across layers', function()
        -- handlers, middleware and framework each carried their own list of
        -- update types; guest_message / managed_bot updates were dispatched
        -- by handlers but invisible to middleware ctx.update_type, and
        -- chat_boost-family updates got no payload in api.build_context.
        local mw
        before_each(function()
            mw = api._middleware
            api._middleware = {}
        end)
        after_each(function()
            api._middleware = mw
        end)

        it('middleware sees update_type for every dispatchable update', function()
            for _, utype in ipairs({
                'guest_message', 'managed_bot', 'chat_boost', 'poll_answer'
            }) do
                local seen
                api._middleware = {}
                api.use(function(ctx, next_fn)
                    seen = ctx.update_type
                    next_fn()
                end)
                api.process_update({ update_id = 1, [utype] = { dummy = true } })
                assert.equals(utype, seen)
            end
        end)

        it('build_context detects every dispatchable update type', function()
            for _, utype in ipairs({
                'chat_boost', 'removed_chat_boost', 'business_connection',
                'deleted_business_messages', 'purchased_paid_media', 'managed_bot'
            }) do
                local payload = { dummy = utype }
                local ctx = api.build_context({ update_id = 1, [utype] = payload })
                assert.equals(utype, ctx.update_type)
                assert.equals(payload, ctx.payload)
            end
        end)

        it('dispatch still routes every update type to its handler', function()
            local originals = {}
            for _, utype in ipairs(api._update_types) do
                originals[utype] = api['on_' .. utype]
            end
            finally(function()
                for utype, fn in pairs(originals) do
                    api['on_' .. utype] = fn
                end
            end)
            for _, utype in ipairs(api._update_types) do
                local got
                api['on_' .. utype] = function(payload) got = payload return 'handled' end
                local payload = { chat = { id = 1, type = 'private' }, dummy = utype }
                local result = api._dispatch_update({ update_id = 1, [utype] = payload })
                assert.equals(payload, got)
                assert.equals('handled', result)
            end
        end)
    end)

    describe('utils fixes', function()
        it('extract_command handles underscores in commands and bot usernames', function()
            local c = api.extract_command({ text = '/my_command@some_bot arg1 arg2' })
            assert.equals('my_command', c.command)
            assert.equals('some_bot', c.bot)
            assert.same({ 'arg1', 'arg2' }, c.args)
            assert.equals('arg1 arg2', c.args_str)
        end)

        it('extract_command handles underscores without a bot suffix', function()
            local c = api.extract_command({ text = '/ban_user 123' })
            assert.equals('ban_user', c.command)
            assert.equals('123', c.args_str)
            assert.same({ '123' }, c.args)
        end)

        it('parse_page_callback round-trips prefixes containing pattern magic', function()
            -- paginate builds data by plain concatenation, so the parser must
            -- not treat the prefix as a lua pattern.
            assert.equals(3, api.parse_page_callback('my-menu:3', 'my-menu'))
            assert.is_nil(api.parse_page_callback('aXb:3', 'a.b'))
        end)

        it('fmt.pre escapes backticks in markdown code blocks', function()
            local out = api.fmt.pre('x = [[```]]', 'lua', 'MarkdownV2')
            -- the inner fence must be escaped so it cannot terminate the block
            assert.is_nil(out:match('\n[^\\]?```[^\n]'))
            assert.truthy(out:find('\\`\\`\\`', 1, true))
        end)

        it('fmt.blockquote escapes MarkdownV2 special characters', function()
            local out = api.fmt.blockquote('1. price is 5-10 USD!', 'MarkdownV2')
            assert.equals('>1\\. price is 5\\-10 USD\\!', out)
        end)

        it('fmt.blockquote still prefixes every line', function()
            local out = api.fmt.blockquote('a\nb', 'MarkdownV2')
            assert.equals('>a\n>b', out)
        end)
    end)
end)
