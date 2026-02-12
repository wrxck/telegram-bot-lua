--[[
    Database adapter for telegram-bot-lua.
    Supports SQLite (via lsqlite3) and PostgreSQL (via pgmoon).
    Async-first: uses non-blocking I/O inside copas, sync fallback otherwise.

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

    -- Connection factory
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
        }

        function conn:execute(sql, params)
            local stmt = self._handle:prepare(sql)
            if not stmt then
                return false, self._handle:errmsg()
            end
            if params then
                stmt:bind_values((table.unpack or unpack)(params))
            end
            local result = stmt:step()
            stmt:finalize()
            if result == sqlite3.DONE then
                return true, self._handle:changes()
            elseif result == sqlite3.ROW then
                return true, 0
            else
                return false, self._handle:errmsg()
            end
        end

        function conn:query(sql, params)
            local stmt = self._handle:prepare(sql)
            if not stmt then
                return nil, self._handle:errmsg()
            end
            if params then
                stmt:bind_values((table.unpack or unpack)(params))
            end
            local rows = {}
            for row in stmt:nrows() do
                rows[#rows + 1] = row
            end
            stmt:finalize()
            return rows
        end

        function conn:close()
            if self._handle then
                self._handle:close()
                self._handle = nil
            end
        end

        function conn:is_connected()
            return self._handle ~= nil
        end

        -- Transaction helpers
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
            self:begin()
            local tx_ok, tx_err = pcall(fn, self)
            if tx_ok then
                self:commit()
                return true
            else
                self:rollback()
                return false, tx_err
            end
        end

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

        -- Replace ? placeholders with escaped values
        local function interpolate(pg_handle, sql, params)
            if not params or #params == 0 then
                return sql
            end
            local idx = 0
            return sql:gsub('%?', function()
                idx = idx + 1
                return escape_param(pg_handle, params[idx])
            end)
        end

        function conn:execute(sql, params)
            local query_str = interpolate(self._handle, sql, params)
            local result, err = self._handle:query(query_str)
            if not result then
                return false, err
            end
            return true, result.affected_rows or 0
        end

        function conn:query(sql, params)
            local query_str = interpolate(self._handle, sql, params)
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

        function conn:is_connected()
            return self._handle ~= nil
        end

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
            self:begin()
            local tx_ok, tx_err = pcall(fn, self)
            if tx_ok then
                self:commit()
                return true
            else
                self:rollback()
                return false, tx_err
            end
        end

        return conn
    end
end
