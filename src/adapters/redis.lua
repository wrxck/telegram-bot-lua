--[[
    Redis adapter for telegram-bot-lua.
    Implements a lightweight Redis client using raw socket commands.
    Async-first: uses copas-wrapped sockets inside copas, plain luasocket otherwise.

    Usage:
        local redis = api.redis.connect({
            host = '127.0.0.1',
            port = 6379,
            password = 'secret',   -- optional
            db = 0,                -- optional, database number
        })

        redis:set('key', 'value')
        redis:set('key', 'value', { ex = 60 })  -- with TTL in seconds
        local val = redis:get('key')
        redis:del('key')
        redis:incr('counter')
        redis:expire('key', 120)
        redis:hset('hash', 'field', 'value')
        local val = redis:hget('hash', 'field')
        redis:close()
]]

return function(api)
    api.redis = {}

    function api.redis.connect(opts)
        opts = opts or {}
        local host = opts.host or '127.0.0.1'
        local port = opts.port or 6379

        local socket = require('socket')
        local sock = socket.tcp()
        sock:settimeout(opts.timeout or 5)

        local ok, err = sock:connect(host, port)
        if not ok then
            error('Failed to connect to Redis at ' .. host .. ':' .. port .. ': ' .. tostring(err))
        end

        -- Wrap with copas if in async context
        if api.adapters.is_async() then
            local copas = require('copas')
            sock = copas.wrap(sock)
        end

        local conn = {
            _sock = sock,
            _host = host,
            _port = port,
        }

        -- RESP protocol: send a command
        local function send_command(sock_handle, ...)
            local args = {...}
            local cmd = '*' .. #args .. '\r\n'
            for _, arg in ipairs(args) do
                local s = tostring(arg)
                cmd = cmd .. '$' .. #s .. '\r\n' .. s .. '\r\n'
            end
            return sock_handle:send(cmd)
        end

        -- RESP protocol: read a response
        local function read_response(sock_handle)
            local line, recv_err = sock_handle:receive('*l')
            if not line then
                return nil, 'Redis read error: ' .. tostring(recv_err)
            end

            local prefix = line:sub(1, 1)
            local data = line:sub(2)

            if prefix == '+' then
                -- Simple string
                return data
            elseif prefix == '-' then
                -- Error
                return nil, data
            elseif prefix == ':' then
                -- Integer
                return tonumber(data)
            elseif prefix == '$' then
                -- Bulk string
                local len = tonumber(data)
                if len == -1 then
                    return nil
                end
                local bulk, bulk_err = sock_handle:receive(len + 2) -- +2 for \r\n
                if not bulk then
                    return nil, 'Redis read error: ' .. tostring(bulk_err)
                end
                return bulk:sub(1, len)
            elseif prefix == '*' then
                -- Array
                local count = tonumber(data)
                if count == -1 then
                    return nil
                end
                local result = {}
                for i = 1, count do
                    result[i] = read_response(sock_handle)
                end
                return result
            else
                return nil, 'Unknown RESP type: ' .. prefix
            end
        end

        -- Execute a raw Redis command and return the response
        function conn:command(...)
            local send_ok, send_err = send_command(self._sock, ...)
            if not send_ok then
                return nil, 'Redis send error: ' .. tostring(send_err)
            end
            return read_response(self._sock)
        end

        -- Authenticate if password provided
        if opts.password then
            local auth_res, auth_err = conn:command('AUTH', opts.password)
            if not auth_res then
                sock:close()
                error('Redis AUTH failed: ' .. tostring(auth_err))
            end
        end

        -- Select database if specified
        if opts.db and opts.db ~= 0 then
            local sel_res, sel_err = conn:command('SELECT', opts.db)
            if not sel_res then
                sock:close()
                error('Redis SELECT failed: ' .. tostring(sel_err))
            end
        end

        -- String commands --

        function conn:get(key)
            return self:command('GET', key)
        end

        function conn:set(key, value, opts_set)
            if opts_set and opts_set.ex then
                return self:command('SET', key, value, 'EX', opts_set.ex)
            elseif opts_set and opts_set.px then
                return self:command('SET', key, value, 'PX', opts_set.px)
            else
                return self:command('SET', key, value)
            end
        end

        function conn:del(...)
            return self:command('DEL', ...)
        end

        function conn:exists(key)
            local result = self:command('EXISTS', key)
            return result == 1
        end

        function conn:incr(key)
            return self:command('INCR', key)
        end

        function conn:decr(key)
            return self:command('DECR', key)
        end

        function conn:incrby(key, amount)
            return self:command('INCRBY', key, amount)
        end

        function conn:mget(...)
            return self:command('MGET', ...)
        end

        function conn:mset(...)
            return self:command('MSET', ...)
        end

        function conn:append(key, value)
            return self:command('APPEND', key, value)
        end

        -- Key commands --

        function conn:expire(key, seconds)
            return self:command('EXPIRE', key, seconds)
        end

        function conn:pexpire(key, milliseconds)
            return self:command('PEXPIRE', key, milliseconds)
        end

        function conn:ttl(key)
            return self:command('TTL', key)
        end

        function conn:pttl(key)
            return self:command('PTTL', key)
        end

        function conn:keys(pattern)
            return self:command('KEYS', pattern or '*')
        end

        function conn:type(key)
            return self:command('TYPE', key)
        end

        function conn:rename(key, newkey)
            return self:command('RENAME', key, newkey)
        end

        -- Hash commands --

        function conn:hget(key, field)
            return self:command('HGET', key, field)
        end

        function conn:hset(key, field, value)
            return self:command('HSET', key, field, value)
        end

        function conn:hdel(key, ...)
            return self:command('HDEL', key, ...)
        end

        function conn:hgetall(key)
            local result = self:command('HGETALL', key)
            if not result or type(result) ~= 'table' then
                return {}
            end
            -- Convert flat array [k1, v1, k2, v2] to table {k1=v1, k2=v2}
            local hash = {}
            for i = 1, #result, 2 do
                hash[result[i]] = result[i + 1]
            end
            return hash
        end

        function conn:hexists(key, field)
            local result = self:command('HEXISTS', key, field)
            return result == 1
        end

        function conn:hincrby(key, field, amount)
            return self:command('HINCRBY', key, field, amount)
        end

        function conn:hkeys(key)
            return self:command('HKEYS', key)
        end

        function conn:hvals(key)
            return self:command('HVALS', key)
        end

        function conn:hlen(key)
            return self:command('HLEN', key)
        end

        -- List commands --

        function conn:lpush(key, ...)
            return self:command('LPUSH', key, ...)
        end

        function conn:rpush(key, ...)
            return self:command('RPUSH', key, ...)
        end

        function conn:lpop(key)
            return self:command('LPOP', key)
        end

        function conn:rpop(key)
            return self:command('RPOP', key)
        end

        function conn:lrange(key, start, stop)
            return self:command('LRANGE', key, start, stop)
        end

        function conn:llen(key)
            return self:command('LLEN', key)
        end

        -- Set commands --

        function conn:sadd(key, ...)
            return self:command('SADD', key, ...)
        end

        function conn:srem(key, ...)
            return self:command('SREM', key, ...)
        end

        function conn:smembers(key)
            return self:command('SMEMBERS', key)
        end

        function conn:sismember(key, member)
            local result = self:command('SISMEMBER', key, member)
            return result == 1
        end

        function conn:scard(key)
            return self:command('SCARD', key)
        end

        -- Sorted set commands --

        function conn:zadd(key, score, member)
            return self:command('ZADD', key, score, member)
        end

        function conn:zrem(key, ...)
            return self:command('ZREM', key, ...)
        end

        function conn:zrange(key, start, stop, withscores)
            if withscores then
                return self:command('ZRANGE', key, start, stop, 'WITHSCORES')
            end
            return self:command('ZRANGE', key, start, stop)
        end

        function conn:zscore(key, member)
            local result = self:command('ZSCORE', key, member)
            return result and tonumber(result)
        end

        function conn:zcard(key)
            return self:command('ZCARD', key)
        end

        -- Server commands --

        function conn:ping()
            return self:command('PING')
        end

        function conn:flushdb()
            return self:command('FLUSHDB')
        end

        function conn:dbsize()
            return self:command('DBSIZE')
        end

        function conn:info(section)
            if section then
                return self:command('INFO', section)
            end
            return self:command('INFO')
        end

        -- Pub/Sub --

        function conn:publish(channel, message)
            return self:command('PUBLISH', channel, message)
        end

        -- Utility: JSON get/set (serialize Lua tables) --

        function conn:jset(key, value, opts_set)
            local json = require('dkjson')
            return self:set(key, json.encode(value), opts_set)
        end

        function conn:jget(key)
            local json = require('dkjson')
            local raw = self:get(key)
            if not raw then return nil end
            return json.decode(raw)
        end

        -- Connection management --

        function conn:close()
            if self._sock then
                pcall(function()
                    send_command(self._sock, 'QUIT')
                    read_response(self._sock)
                end)
                self._sock:close()
                self._sock = nil
            end
        end

        function conn:is_connected()
            if not self._sock then return false end
            local ping_ok = pcall(function()
                send_command(self._sock, 'PING')
                read_response(self._sock)
            end)
            return ping_ok
        end

        return conn
    end
end
