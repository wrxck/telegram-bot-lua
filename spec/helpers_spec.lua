local api = require('spec.test_helper')

describe('helpers', function()
    before_each(function()
        api._clear_requests()
    end)

    describe('is_user_kicked', function()
        it('returns false for missing params', function()
            assert.is_false(api.is_user_kicked(nil, 123))
            assert.is_false(api.is_user_kicked(123, nil))
        end)

        it('returns true when user is kicked', function()
            api._mock_response({ ok = true, result = { status = 'kicked' }})
            assert.is_true(api.is_user_kicked(123, 456))
        end)

        it('returns false when user is not kicked', function()
            api._mock_response({ ok = true, result = { status = 'member' }})
            local result, status = api.is_user_kicked(123, 456)
            assert.is_false(result)
            assert.equals('member', status)
        end)
    end)

    describe('is_user_group_admin', function()
        it('returns true for administrators', function()
            api._mock_response({ ok = true, result = { status = 'administrator' }})
            assert.is_true(api.is_user_group_admin(123, 456))
        end)

        it('returns true for creators (bug fix from v2)', function()
            api._mock_response({ ok = true, result = { status = 'creator' }})
            assert.is_true(api.is_user_group_admin(123, 456))
        end)

        it('returns false for regular members', function()
            api._mock_response({ ok = true, result = { status = 'member' }})
            assert.is_false(api.is_user_group_admin(123, 456))
        end)
    end)

    describe('is_user_group_creator', function()
        it('returns true for creators', function()
            api._mock_response({ ok = true, result = { status = 'creator' }})
            assert.is_true(api.is_user_group_creator(123, 456))
        end)

        it('returns false for administrators', function()
            api._mock_response({ ok = true, result = { status = 'administrator' }})
            assert.is_false(api.is_user_group_creator(123, 456))
        end)
    end)

    describe('is_user_restricted', function()
        it('returns true for restricted users (bug fix from v2)', function()
            api._mock_response({ ok = true, result = { status = 'restricted' }})
            assert.is_true(api.is_user_restricted(123, 456))
        end)

        it('returns false for kicked users', function()
            api._mock_response({ ok = true, result = { status = 'kicked' }})
            assert.is_false(api.is_user_restricted(123, 456))
        end)
    end)

    describe('has_user_left', function()
        it('returns true for users who left', function()
            api._mock_response({ ok = true, result = { status = 'left' }})
            assert.is_true(api.has_user_left(123, 456))
        end)
    end)

    describe('get_chat_member_permissions', function()
        it('returns false for missing params', function()
            assert.is_false(api.get_chat_member_permissions(nil, 123))
        end)

        it('returns permissions table', function()
            api._mock_response({ ok = true, result = {
                status = 'administrator',
                can_manage_chat = true,
                can_delete_messages = true,
                can_manage_direct_messages = true
            }})
            local perms = api.get_chat_member_permissions(123, 456)
            assert.is_table(perms)
            assert.is_true(perms.can_manage_chat)
            assert.is_true(perms.can_delete_messages)
            assert.is_true(perms.can_manage_direct_messages)
            assert.is_false(perms.can_pin_messages)
        end)
    end)
end)
