--- database adapter supporting SQLite and PostgreSQL.
-- @module telegram-bot-lua.adapters.db
--[[
    Database adapter for telegram-bot-lua.
    Supports SQLite (via lsqlite3) and PostgreSQL (via pgmoon).
    Note: the SQLite driver (lsqlite3) is synchronous and blocking; it does not
    yield inside copas. PostgreSQL (via pgmoon) uses a copas-wrapped socket and
    is non-blocking when running inside a copas context.

    Usage:
        local db = api.db.connect({
            driver = 'sqlite',
            path = 'bot.db'
        })

        local db = api.db.connect({
            driver = 'postgres',
            host = 'localhost',
            port = 5432,
            database = 'mybot',
            user = 'botuser',
            password = 'secret'
        })

        db:execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)')
        db:execute('INSERT INTO users (id, name) VALUES (?, ?)', {123, 'Alice'})
        local rows = db:query('SELECT * FROM users WHERE id = ?', {123})
        db:close()
]]

return function(api)
    api.db = {}

    -- transaction helpers shared by both drivers, built on conn:execute.
    -- begin/commit failures are surfaced instead of ignored: a failed BEGIN
    -- (e.g. a transaction is already open) used to let the inner
    -- commit/rollback silently terminate the caller's outer transaction.
    local function attach_transaction_helpers(conn)
        function conn:begin()
            return self:execute('BEGIN')
        end

        function conn:commit()
            return self:execute('COMMIT')
        end

        function conn:rollback()
            return self:execute('ROLLBACK')
        end

        function conn:transaction(fn)
            local began, begin_err = self:begin()
            if not began then
                return false, tostring(begin_err)
            end
            local tx_ok, tx_err = pcall(fn, self)
            if tx_ok then
                local committed, commit_err = self:commit()
                if not committed then
                    self:rollback()
                    return false, tostring(commit_err)
                end
                return true
            end
            self:rollback()
            return false, tx_err
        end

        function conn:is_connected()
            return self._handle ~= nil
        end
    end

    --- create a database connection.
    -- @param opts table connection options
    -- @param opts.driver string database driver: 'sqlite' or 'postgres'
    -- @param opts.path string SQLite database file path (sqlite only)
    -- @param opts.host string PostgreSQL host (postgres only)
    -- @param opts.port number PostgreSQL port (postgres only)
    -- @param opts.database string PostgreSQL database name (postgres only)
    -- @param opts.user string PostgreSQL username (postgres only)
    -- @param opts.password string PostgreSQL password (postgres only)
    -- @return table connection object with execute, query, close methods
    function api.db.connect(opts)
        assert(opts and opts.driver, 'db.connect requires a driver option (sqlite, postgres)')
        local driver = opts.driver:lower()

        if driver == 'sqlite' or driver == 'sqlite3' then
            return api.db._connect_sqlite(opts)
        elseif driver == 'postgres' or driver == 'postgresql' or driver == 'pg' then
            return api.db._connect_postgres(opts)
        else
            error('Unsupported database driver: ' .. tostring(opts.driver) .. '. Supported: sqlite, postgres')
        end
    end

    -- SQLite driver --

    function api.db._connect_sqlite(opts)
        local ok, sqlite3 = pcall(require, 'lsqlite3')
        if not ok then
            ok, sqlite3 = pcall(require, 'lsqlite3complete')
        end
        if not ok then
            error('SQLite requires the lsqlite3 library. Install with: luarocks install lsqlite3')
        end

        local path = opts.path or ':memory:'
        local db_handle = sqlite3.open(path)
        if not db_handle then
            error('Failed to open SQLite database: ' .. tostring(path))
        end

        -- Enable WAL mode for better concurrency
        db_handle:exec('PRAGMA journal_mode=WAL')

        local conn = {
            _handle = db_handle,
            _driver = 'sqlite',
            _path = path,
            -- compiled statements keyed by sql string, reset (not finalised)
            -- between calls so hot queries are not recompiled every time.
            _stmt_cache = {},
            _stmt_cache_count = 0,
        }

        -- bound on the number of cached statements. when exceeded the cache is
        -- finalised and cleared, so long-lived connections issuing many unique
        -- statements do not leak compiled-statement handles.
        local STMT_CACHE_LIMIT = 128

        -- finalise and drop every cached statement.
        local function clear_stmt_cache(self)
            for _, stmt in pairs(self._stmt_cache) do
                pcall(function() stmt:finalize() end)
            end
            self._stmt_cache = {}
            self._stmt_cache_count = 0
        end

        -- fetch a compiled statement for sql, preferring the cache. a cached
        -- statement is reset before reuse, and its bindings are cleared:
        -- sqlite3_reset does not clear bindings, so a later call with fewer
        -- (or no) parameters would otherwise silently reuse the previous
        -- call's values. returns (stmt) or (nil, errmsg).
        local function get_stmt(self, sql)
            local cached = self._stmt_cache[sql]
            if cached then
                cached:reset()
                if cached.clear_bindings then
                    cached:clear_bindings()
                else
                    for i = 1, cached:bind_parameter_count() do
                        cached:bind(i, nil)
                    end
                end
                return cached
            end
            local stmt = self._handle:prepare(sql)
            if not stmt then
                return nil, self._handle:errmsg()
            end
            if self._stmt_cache_count >= STMT_CACHE_LIMIT then
                clear_stmt_cache(self)
            end
            self._stmt_cache[sql] = stmt
            self._stmt_cache_count = self._stmt_cache_count + 1
            return stmt
        end

        function conn:execute(sql, params)
            local stmt, prep_err = get_stmt(self, sql)
            if not stmt then
                return false, prep_err
            end
            if params then
                -- bind_values raises on a parameter-count mismatch; this
                -- method's contract is (false, err).
                local bind_ok, bind_err = pcall(stmt.bind_values, stmt, (table.unpack or unpack)(params))
                if not bind_ok then
                    stmt:reset()
                    return false, tostring(bind_err)
                end
            end
            local result = stmt:step()
            -- reset (not finalise) so the cached statement is reusable.
            stmt:reset()
            if result == sqlite3.DONE then
                return true, self._handle:changes()
            elseif result == sqlite3.ROW then
                return true, 0
            else
                return false, self._handle:errmsg()
            end
        end

        function conn:query(sql, params)
            local stmt, prep_err = get_stmt(self, sql)
            if not stmt then
                return nil, prep_err
            end
            if params then
                local bind_ok, bind_err = pcall(stmt.bind_values, stmt, (table.unpack or unpack)(params))
                if not bind_ok then
                    stmt:reset()
                    return nil, tostring(bind_err)
                end
            end
            local rows = {}
            for row in stmt:nrows() do
                rows[#rows + 1] = row
            end
            -- nrows() drives the statement to completion; reset for reuse.
            stmt:reset()
            return rows
        end

        function conn:close()
            if self._handle then
                clear_stmt_cache(self)
                self._handle:close()
                self._handle = nil
            end
        end

        attach_transaction_helpers(conn)

        return conn
    end

    -- PostgreSQL driver --

    function api.db._connect_postgres(opts)
        local ok, pgmoon = pcall(require, 'pgmoon')
        if not ok then
            error('PostgreSQL requires the pgmoon library. Install with: luarocks install pgmoon')
        end

        local pg = pgmoon.new({
            host = opts.host or '127.0.0.1',
            port = opts.port or 5432,
            database = opts.database or opts.db,
            user = opts.user or opts.username,
            password = opts.password,
            ssl = opts.ssl,
        })

        local conn_ok, conn_err = pg:connect()
        if not conn_ok then
            error('Failed to connect to PostgreSQL: ' .. tostring(conn_err))
        end

        -- If in async context, enable copas socket
        if api.adapters.is_async() then
            local copas = require('copas')
            if pg.sock then
                pg.sock = copas.wrap(pg.sock)
            end
        end

        local conn = {
            _handle = pg,
            _driver = 'postgres',
        }

        -- Escape a value for safe SQL interpolation
        local function escape_param(pg_handle, val)
            if val == nil then
                return 'NULL'
            elseif type(val) == 'number' then
                return tostring(val)
            elseif type(val) == 'boolean' then
                return val and 'TRUE' or 'FALSE'
            else
                return pg_handle:escape_literal(tostring(val))
            end
        end

        -- Replace ? placeholders with escaped values. quote-aware: a literal
        -- '?' inside a single-quoted string (with '' escapes) is left alone,
        -- and running out of parameters is an error rather than a silent
        -- NULL, both of which used to corrupt the query.
        local function interpolate(pg_handle, sql, params)
            if not params or #params == 0 then
                return sql
            end
            local out = {}
            local idx = 0
            local i = 1
            local len = #sql
            while i <= len do
                local char = sql:sub(i, i)
                if char == "'" then
                    -- copy the quoted literal verbatim, honouring '' escapes
                    local j = i + 1
                    while j <= len do
                        if sql:sub(j, j) == "'" then
                            if sql:sub(j + 1, j + 1) == "'" then
                                j = j + 2
                            else
                                break
                            end
                        else
                            j = j + 1
                        end
                    end
                    out[#out + 1] = sql:sub(i, j)
                    i = j + 1
                elseif char == '?' then
                    idx = idx + 1
                    if idx > #params then
                        return nil, 'missing parameter #' .. idx .. ' for sql placeholder'
                    end
                    out[#out + 1] = escape_param(pg_handle, params[idx])
                    i = i + 1
                else
                    out[#out + 1] = char
                    i = i + 1
                end
            end
            return table.concat(out)
        end

        function conn:execute(sql, params)
            local query_str, interp_err = interpolate(self._handle, sql, params)
            if not query_str then
                return false, interp_err
            end
            local result, err = self._handle:query(query_str)
            if not result then
                return false, err
            end
            return true, result.affected_rows or 0
        end

        function conn:query(sql, params)
            local query_str, interp_err = interpolate(self._handle, sql, params)
            if not query_str then
                return nil, interp_err
            end
            local result, err = self._handle:query(query_str)
            if not result then
                return nil, err
            end
            -- pgmoon returns array of row tables
            if type(result) == 'table' then
                return result
            end
            return {}
        end

        function conn:close()
            if self._handle then
                self._handle:disconnect()
                self._handle = nil
            end
        end

        attach_transaction_helpers(conn)

        return conn
    end
end
