--- Redis client adapter using raw RESP protocol.
-- @module telegram-bot-lua.adapters.redis
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

    --- connect to a Redis server.
    -- @param opts table connection options
    -- @param opts.host string Redis host (default '127.0.0.1')
    -- @param opts.port number Redis port (default 6379)
    -- @param opts.password string authentication password
    -- @param opts.db number database number to select
    -- @param opts.timeout number connection timeout in seconds (default 5)
    -- @return table Redis connection object with command methods
    function api.redis.connect(opts)
        opts = opts or {}
        local host = opts.host or '127.0.0.1'
        local port = opts.port or 6379

        local socket = require('socket')

        -- open a fresh tcp socket to the server and wrap it for copas when
        -- inside an async context. shared by the initial connect and reconnect.
        local function open_socket()
            local raw = socket.tcp()
            raw:settimeout(opts.timeout or 5)
            local ok, err = raw:connect(host, port)
            if not ok then
                return nil, err
            end
            if api.adapters.is_async() then
                local copas = require('copas')
                raw = copas.wrap(raw)
            end
            return raw
        end

        local sock, conn_err = open_socket()
        if not sock then
            error('Failed to connect to Redis at ' .. host .. ':' .. port .. ': ' .. tostring(conn_err))
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
                    local element, element_err = read_response(sock_handle)
                    if element == nil then
                        if element_err then
                            -- a transport/protocol failure mid-array leaves the
                            -- stream desynced; surface the error instead of
                            -- returning a partial array as success.
                            return nil, element_err
                        end
                        -- a null bulk ($-1) inside an array is represented as
                        -- false: a nil hole would truncate #result and make
                        -- later elements unreachable via ipairs.
                        element = false
                    end
                    result[i] = element
                end
                return result
            else
                return nil, 'Unknown RESP type: ' .. prefix
            end
        end

        -- run a command once over a given socket without any reconnect logic.
        -- returns (value, err, transport_failed) where transport_failed is true
        -- when the socket itself looks dead (send/receive failed) rather than
        -- the server returning a normal RESP error.
        local function exec_once(sock_handle, ...)
            local send_ok, send_err = send_command(sock_handle, ...)
            if not send_ok then
                return nil, 'Redis send error: ' .. tostring(send_err), true
            end
            local value, read_err = read_response(sock_handle)
            -- a nil value with a read-error string means the receive failed,
            -- which we treat as a dead socket worth a reconnect. a server-side
            -- RESP error (e.g. wrong type) returns a non-transport message.
            if value == nil and read_err and read_err:find('^Redis read error') then
                return nil, read_err, true
            end
            return value, read_err
        end

        -- replay the authentication and database selection on a fresh socket.
        -- used both on initial connect and after a reconnect so the new socket
        -- ends up in the same logical state as the old one.
        local function authenticate(sock_handle)
            if opts.password then
                local auth_res, auth_err = exec_once(sock_handle, 'AUTH', opts.password)
                if not auth_res then
                    return false, 'Redis AUTH failed: ' .. tostring(auth_err)
                end
            end
            if opts.db and opts.db ~= 0 then
                local sel_res, sel_err = exec_once(sock_handle, 'SELECT', opts.db)
                if not sel_res then
                    return false, 'Redis SELECT failed: ' .. tostring(sel_err)
                end
            end
            return true
        end

        -- tear down the dead socket and open a new authenticated one, retaining
        -- the same db/auth state. returns true on success.
        local function reconnect(self)
            if self._sock then
                pcall(function() self._sock:close() end)
            end
            local new_sock, open_err = open_socket()
            if not new_sock then
                return false, open_err
            end
            local auth_ok, auth_err = authenticate(new_sock)
            if not auth_ok then
                pcall(function() new_sock:close() end)
                return false, auth_err
            end
            self._sock = new_sock
            return true
        end

        -- execute a raw redis command. if the socket is found dead, attempt a
        -- single reconnect (re-running the connect path) and retry the command
        -- once before giving up.
        function conn:command(...)
            if not self._sock then
                return nil, 'Redis connection is closed'
            end
            local value, cmd_err, transport_failed = exec_once(self._sock, ...)
            if transport_failed then
                local ok_reconnect = reconnect(self)
                if not ok_reconnect then
                    return nil, cmd_err
                end
                -- trim exec_once's third return (transport_failed) so it
                -- never leaks into the public (value, err) signature.
                local retry_value, retry_err = exec_once(self._sock, ...)
                return retry_value, retry_err
            end
            return value, cmd_err
        end

        -- authenticate and select the database on the initial connection.
        local init_ok, init_err = authenticate(conn._sock)
        if not init_ok then
            conn._sock:close()
            error(init_err)
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

        -- one SCAN step. returns (next_cursor, keys_table). the cursor is a
        -- string; iteration is complete once it comes back as '0'. opts may
        -- carry a match pattern and a count hint.
        function conn:scan(cursor, scan_opts)
            scan_opts = scan_opts or {}
            local args = { 'SCAN', cursor or '0' }
            if scan_opts.match then
                args[#args + 1] = 'MATCH'
                args[#args + 1] = scan_opts.match
            end
            if scan_opts.count then
                args[#args + 1] = 'COUNT'
                args[#args + 1] = scan_opts.count
            end
            local result, err = self:command((table.unpack or unpack)(args))
            if not result then
                return nil, err
            end
            -- SCAN replies with [next_cursor, [key, ...]]
            return tostring(result[1]), result[2] or {}
        end

        -- non-blocking alternative to keys('*'): iterates SCAN until the cursor
        -- returns to '0' and collects every matching key.
        function conn:scan_all(pattern)
            local found = {}
            local cursor = '0'
            repeat
                local next_cursor, batch = self:scan(cursor, { match = pattern })
                if not next_cursor then
                    return nil, batch
                end
                for _, key in ipairs(batch) do
                    found[#found + 1] = key
                end
                cursor = next_cursor
            until cursor == '0'
            return found
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
            -- send/receive report failure via (nil, err) rather than raising,
            -- so the result must actually be checked: a dead socket used to
            -- make this return true.
            local value = exec_once(self._sock, 'PING')
            return value == 'PONG'
        end

        return conn
    end
end
