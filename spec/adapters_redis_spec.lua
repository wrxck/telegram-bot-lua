local api = require('spec.test_helper')

-- Redis tests require a running Redis server.
-- They are skipped if Redis is not available.
local function redis_available()
    local socket = require('socket')
    local sock = socket.tcp()
    sock:settimeout(1)
    local ok = sock:connect('127.0.0.1', 6379)
    sock:close()
    return ok
end

describe('redis adapter', function()
    describe('module', function()
        it('api.redis exists', function()
            assert.is_table(api.redis)
        end)

        it('has connect function', function()
            assert.is_function(api.redis.connect)
        end)

        it('errors on unreachable host', function()
            assert.has_error(function()
                api.redis.connect({ host = '127.0.0.1', port = 49999, timeout = 1 })
            end)
        end)
    end)

    -- Integration tests (require running Redis)
    local has_redis = redis_available()

    if has_redis then
        describe('integration', function()
            local redis

            before_each(function()
                redis = api.redis.connect({ host = '127.0.0.1', port = 6379 })
                -- Use a test prefix to avoid conflicts
                redis:command('SELECT', 15) -- use DB 15 for tests
                -- Clean up test keys from prior runs
                local keys = redis:keys('*')
                if keys and #keys > 0 then
                    for _, k in ipairs(keys) do
                        redis:del(k)
                    end
                end
            end)

            after_each(function()
                if redis then
                    pcall(function()
                        local keys = redis:keys('*')
                        if keys and #keys > 0 then
                            for _, k in ipairs(keys) do
                                redis:del(k)
                            end
                        end
                    end)
                    redis:close()
                end
            end)

            it('connects and pings', function()
                local result = redis:ping()
                assert.equals('PONG', result)
            end)

            describe('strings', function()
                it('set and get', function()
                    redis:set('test_key', 'hello')
                    assert.equals('hello', redis:get('test_key'))
                end)

                it('get returns nil for missing key', function()
                    assert.is_nil(redis:get('nonexistent_key'))
                end)

                it('set with TTL', function()
                    redis:set('ttl_key', 'value', { ex = 10 })
                    local ttl = redis:ttl('ttl_key')
                    assert.truthy(ttl > 0 and ttl <= 10)
                end)

                it('del removes key', function()
                    redis:set('del_key', 'value')
                    redis:del('del_key')
                    assert.is_nil(redis:get('del_key'))
                end)

                it('exists checks key existence', function()
                    redis:set('exists_key', 'value')
                    assert.is_true(redis:exists('exists_key'))
                    assert.is_false(redis:exists('no_such_key'))
                end)

                it('incr and decr', function()
                    redis:set('counter', '10')
                    redis:incr('counter')
                    assert.equals('11', redis:get('counter'))
                    redis:decr('counter')
                    assert.equals('10', redis:get('counter'))
                end)

                it('incrby increments by amount', function()
                    redis:set('counter2', '0')
                    redis:incrby('counter2', 5)
                    assert.equals('5', redis:get('counter2'))
                end)

                it('append to string', function()
                    redis:set('append_key', 'hello')
                    redis:append('append_key', ' world')
                    assert.equals('hello world', redis:get('append_key'))
                end)
            end)

            describe('keys', function()
                it('expire sets TTL', function()
                    redis:set('exp_key', 'value')
                    redis:expire('exp_key', 30)
                    local ttl = redis:ttl('exp_key')
                    assert.truthy(ttl > 0 and ttl <= 30)
                end)

                it('keys returns matching keys', function()
                    redis:set('prefix:a', '1')
                    redis:set('prefix:b', '2')
                    redis:set('other:c', '3')
                    local keys = redis:keys('prefix:*')
                    assert.equals(2, #keys)
                end)

                it('type returns key type', function()
                    redis:set('str_key', 'value')
                    assert.equals('string', redis:type('str_key'))
                end)

                it('rename renames key', function()
                    redis:set('old_name', 'value')
                    redis:rename('old_name', 'new_name')
                    assert.is_nil(redis:get('old_name'))
                    assert.equals('value', redis:get('new_name'))
                end)
            end)

            describe('hashes', function()
                it('hset and hget', function()
                    redis:hset('myhash', 'field1', 'value1')
                    assert.equals('value1', redis:hget('myhash', 'field1'))
                end)

                it('hgetall returns table', function()
                    redis:hset('hash2', 'a', '1')
                    redis:hset('hash2', 'b', '2')
                    local hash = redis:hgetall('hash2')
                    assert.equals('1', hash.a)
                    assert.equals('2', hash.b)
                end)

                it('hdel removes field', function()
                    redis:hset('hash3', 'f', 'v')
                    redis:hdel('hash3', 'f')
                    assert.is_nil(redis:hget('hash3', 'f'))
                end)

                it('hexists checks field', function()
                    redis:hset('hash4', 'exists', 'yes')
                    assert.is_true(redis:hexists('hash4', 'exists'))
                    assert.is_false(redis:hexists('hash4', 'nope'))
                end)

                it('hincrby increments hash field', function()
                    redis:hset('hash5', 'count', '10')
                    redis:hincrby('hash5', 'count', 3)
                    assert.equals('13', redis:hget('hash5', 'count'))
                end)

                it('hkeys and hvals', function()
                    redis:hset('hash6', 'x', '1')
                    redis:hset('hash6', 'y', '2')
                    local keys = redis:hkeys('hash6')
                    local vals = redis:hvals('hash6')
                    assert.equals(2, #keys)
                    assert.equals(2, #vals)
                end)

                it('hlen returns field count', function()
                    redis:hset('hash7', 'a', '1')
                    redis:hset('hash7', 'b', '2')
                    redis:hset('hash7', 'c', '3')
                    assert.equals(3, redis:hlen('hash7'))
                end)
            end)

            describe('lists', function()
                it('lpush and rpush', function()
                    redis:lpush('list1', 'a')
                    redis:rpush('list1', 'b')
                    redis:lpush('list1', 'c')
                    local items = redis:lrange('list1', 0, -1)
                    assert.equals(3, #items)
                    assert.equals('c', items[1])
                    assert.equals('a', items[2])
                    assert.equals('b', items[3])
                end)

                it('lpop and rpop', function()
                    redis:rpush('list2', 'a')
                    redis:rpush('list2', 'b')
                    redis:rpush('list2', 'c')
                    assert.equals('a', redis:lpop('list2'))
                    assert.equals('c', redis:rpop('list2'))
                end)

                it('llen returns list length', function()
                    redis:rpush('list3', 'a')
                    redis:rpush('list3', 'b')
                    assert.equals(2, redis:llen('list3'))
                end)
            end)

            describe('sets', function()
                it('sadd and smembers', function()
                    redis:sadd('set1', 'a')
                    redis:sadd('set1', 'b')
                    redis:sadd('set1', 'c')
                    local members = redis:smembers('set1')
                    assert.equals(3, #members)
                end)

                it('sismember checks membership', function()
                    redis:sadd('set2', 'member')
                    assert.is_true(redis:sismember('set2', 'member'))
                    assert.is_false(redis:sismember('set2', 'nonmember'))
                end)

                it('srem removes member', function()
                    redis:sadd('set3', 'a')
                    redis:sadd('set3', 'b')
                    redis:srem('set3', 'a')
                    assert.equals(1, redis:scard('set3'))
                end)

                it('scard returns set size', function()
                    redis:sadd('set4', 'a')
                    redis:sadd('set4', 'b')
                    redis:sadd('set4', 'c')
                    assert.equals(3, redis:scard('set4'))
                end)
            end)

            describe('sorted sets', function()
                it('zadd and zscore', function()
                    redis:zadd('zset1', 1.5, 'a')
                    redis:zadd('zset1', 2.5, 'b')
                    assert.equals(1.5, redis:zscore('zset1', 'a'))
                    assert.equals(2.5, redis:zscore('zset1', 'b'))
                end)

                it('zrange returns ordered members', function()
                    redis:zadd('zset2', 3, 'c')
                    redis:zadd('zset2', 1, 'a')
                    redis:zadd('zset2', 2, 'b')
                    local members = redis:zrange('zset2', 0, -1)
                    assert.equals('a', members[1])
                    assert.equals('b', members[2])
                    assert.equals('c', members[3])
                end)

                it('zcard returns set size', function()
                    redis:zadd('zset3', 1, 'a')
                    redis:zadd('zset3', 2, 'b')
                    assert.equals(2, redis:zcard('zset3'))
                end)

                it('zrem removes member', function()
                    redis:zadd('zset4', 1, 'a')
                    redis:zadd('zset4', 2, 'b')
                    redis:zrem('zset4', 'a')
                    assert.equals(1, redis:zcard('zset4'))
                end)
            end)

            describe('json helpers', function()
                it('jset and jget roundtrip tables', function()
                    local data = { name = 'Alice', age = 30, tags = {'a', 'b'} }
                    redis:jset('json_key', data)
                    local result = redis:jget('json_key')
                    assert.equals('Alice', result.name)
                    assert.equals(30, result.age)
                    assert.equals(2, #result.tags)
                end)

                it('jget returns nil for missing key', function()
                    assert.is_nil(redis:jget('missing_json'))
                end)

                it('jset with TTL', function()
                    redis:jset('json_ttl', { value = true }, { ex = 10 })
                    local result = redis:jget('json_ttl')
                    assert.is_true(result.value)
                    local ttl = redis:ttl('json_ttl')
                    assert.truthy(ttl > 0)
                end)
            end)

            describe('server', function()
                it('dbsize returns count', function()
                    redis:set('a', '1')
                    redis:set('b', '2')
                    local size = redis:dbsize()
                    assert.truthy(size >= 2)
                end)
            end)

            describe('connection', function()
                it('is_connected returns true when connected', function()
                    assert.is_true(redis:is_connected())
                end)

                it('close disconnects', function()
                    redis:close()
                    assert.is_false(redis:is_connected())
                    redis = nil -- prevent after_each from closing again
                end)
            end)
        end)
    else
        pending('Redis integration tests skipped - no Redis server on 127.0.0.1:6379')
    end
end)
