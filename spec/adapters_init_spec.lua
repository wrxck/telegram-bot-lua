local api = require('spec.test_helper')

describe('adapters', function()
    describe('module', function()
        it('api.adapters exists', function()
            assert.is_table(api.adapters)
        end)

        it('has is_async function', function()
            assert.is_function(api.adapters.is_async)
        end)

        it('has http_request function', function()
            assert.is_function(api.adapters.http_request)
        end)

        it('has create_socket function', function()
            assert.is_function(api.adapters.create_socket)
        end)
    end)

    describe('is_async', function()
        it('returns false outside copas context', function()
            assert.is_false(api.adapters.is_async())
        end)

        it('returns true inside copas context', function()
            local copas = require('copas')
            local result
            copas.addthread(function()
                result = api.adapters.is_async()
            end)
            copas.loop()
            assert.is_true(result)
        end)
    end)

    describe('sub-adapters loaded', function()
        it('api.db exists', function()
            assert.is_table(api.db)
        end)

        it('api.redis exists', function()
            assert.is_table(api.redis)
        end)

        it('api.llm exists', function()
            assert.is_table(api.llm)
        end)

        it('api.email exists', function()
            assert.is_table(api.email)
        end)
    end)
end)

describe('async-first run', function()
    it('api.run exists', function()
        assert.is_function(api.run)
    end)

    it('api._run_sync exists', function()
        assert.is_function(api._run_sync)
    end)

    it('api.run defaults to async (delegates to api.async.run)', function()
        -- Verify that api.run calls api.async.run by default
        local async_run_called = false
        local original_async_run = api.async.run
        api.async.run = function(opts)
            async_run_called = true
        end

        api.run({ timeout = 0 })
        assert.is_true(async_run_called)

        api.async.run = original_async_run
    end)

    it('api.run with sync=true uses _run_sync', function()
        -- Verify that sync=true skips async.run
        local async_run_called = false
        local original_async_run = api.async.run

        -- Mock async.run to detect if called
        api.async.run = function(opts)
            async_run_called = true
        end

        -- Mock _run_sync to not loop forever
        local sync_called = false
        local original_run_sync = api._run_sync
        api._run_sync = function(opts)
            sync_called = true
        end

        api.run({ sync = true, timeout = 0 })
        assert.is_false(async_run_called)
        assert.is_true(sync_called)

        api.async.run = original_async_run
        api._run_sync = original_run_sync
    end)
end)
