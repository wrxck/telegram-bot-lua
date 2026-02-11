local api = require('spec.test_helper')

describe('handlers', function()
    describe('process_update', function()
        it('returns false for nil update', function()
            assert.is_false(api.process_update(nil))
        end)

        it('calls on_update for every update', function()
            local called = false
            api.on_update = function(_) called = true end
            api.process_update({ message = { chat = { type = 'private' }, text = 'hi' }})
            assert.is_true(called)
            api.on_update = function(_) end
        end)

        it('routes message to on_message', function()
            local msg = nil
            api.on_message = function(m) msg = m end
            local update = { message = { chat = { type = 'private' }, text = 'hello' }}
            api.process_update(update)
            assert.equals('hello', msg.text)
            api.on_message = function(_) end
        end)

        it('routes private message to on_private_message', function()
            local called = false
            api.on_private_message = function(_) called = true end
            api.process_update({ message = { chat = { type = 'private' }}})
            assert.is_true(called)
            api.on_private_message = function(_) end
        end)

        it('routes group message to on_group_message', function()
            local called = false
            api.on_group_message = function(_) called = true end
            api.process_update({ message = { chat = { type = 'group' }}})
            assert.is_true(called)
            api.on_group_message = function(_) end
        end)

        it('routes supergroup message to on_supergroup_message', function()
            local called = false
            api.on_supergroup_message = function(_) called = true end
            api.process_update({ message = { chat = { type = 'supergroup' }}})
            assert.is_true(called)
            api.on_supergroup_message = function(_) end
        end)

        it('routes edited_message', function()
            local called = false
            api.on_edited_message = function(_) called = true end
            api.process_update({ edited_message = { chat = { type = 'private' }}})
            assert.is_true(called)
            api.on_edited_message = function(_) end
        end)

        it('routes callback_query', function()
            local called = false
            api.on_callback_query = function(_) called = true end
            api.process_update({ callback_query = { id = '123' }})
            assert.is_true(called)
            api.on_callback_query = function(_) end
        end)

        it('routes inline_query', function()
            local called = false
            api.on_inline_query = function(_) called = true end
            api.process_update({ inline_query = { id = '123' }})
            assert.is_true(called)
            api.on_inline_query = function(_) end
        end)

        it('routes channel_post', function()
            local called = false
            api.on_channel_post = function(_) called = true end
            api.process_update({ channel_post = { text = 'hi' }})
            assert.is_true(called)
            api.on_channel_post = function(_) end
        end)

        it('routes poll_answer (bug fix from v2)', function()
            local called = false
            api.on_poll_answer = function(_) called = true end
            api.process_update({ poll_answer = { poll_id = '1' }})
            assert.is_true(called)
            api.on_poll_answer = function(_) end
        end)

        it('routes message_reaction (bug fix from v2)', function()
            local called = false
            api.on_message_reaction = function(_) called = true end
            api.process_update({ message_reaction = { chat = {} }})
            assert.is_true(called)
            api.on_message_reaction = function(_) end
        end)

        it('routes business_connection (new in v3)', function()
            local called = false
            api.on_business_connection = function(_) called = true end
            api.process_update({ business_connection = { id = '1' }})
            assert.is_true(called)
            api.on_business_connection = function(_) end
        end)

        it('routes purchased_paid_media (new in v3)', function()
            local called = false
            api.on_purchased_paid_media = function(_) called = true end
            api.process_update({ purchased_paid_media = {} })
            assert.is_true(called)
            api.on_purchased_paid_media = function(_) end
        end)

        it('returns false for unknown update type', function()
            assert.is_false(api.process_update({ unknown_type = {} }))
        end)
    end)
end)
