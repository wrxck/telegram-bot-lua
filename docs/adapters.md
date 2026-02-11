# Adapters

telegram-bot-lua v3.0 includes built-in adapters for databases, Redis, LLMs, and email. All adapters are async-first: they automatically use non-blocking I/O when running inside the copas event loop (the default for `api.run()`), and fall back to synchronous I/O when called outside it.

## Database (`api.db`)

Supports SQLite (via `lsqlite3`) and PostgreSQL (via `pgmoon`). Install the driver for your database:

```
luarocks install lsqlite3        # SQLite
luarocks install pgmoon           # PostgreSQL
```

### Connecting

```lua
-- SQLite (in-memory)
local db = api.db.connect({ driver = 'sqlite', path = ':memory:' })

-- SQLite (file)
local db = api.db.connect({ driver = 'sqlite', path = '/path/to/bot.db' })

-- PostgreSQL
local db = api.db.connect({
    driver = 'postgres',
    host = '127.0.0.1',
    port = 5432,
    database = 'mybot',
    user = 'botuser',
    password = 'secret',
    ssl = true, -- optional
})
```

### Queries

```lua
-- Create table
db:execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, points INTEGER)')

-- Insert with parameters (? placeholders)
db:execute('INSERT INTO users (id, name, points) VALUES (?, ?, ?)', {123, 'Alice', 100})

-- Query returns array of row tables
local rows = db:query('SELECT * FROM users WHERE points > ?', {50})
for _, row in ipairs(rows) do
    print(row.name, row.points)
end

-- Execute returns ok, changes_count
local ok, changes = db:execute('DELETE FROM users WHERE points = 0')
```

### Transactions

```lua
-- Automatic: rolls back on error, commits on success
local ok, err = db:transaction(function(conn)
    conn:execute('UPDATE users SET points = points - 10 WHERE id = ?', {sender_id})
    conn:execute('UPDATE users SET points = points + 10 WHERE id = ?', {receiver_id})
end)

-- Manual
db:begin()
db:execute('INSERT INTO log VALUES (?)', {'event'})
db:commit()  -- or db:rollback()
```

### Connection Management

```lua
db:is_connected()  -- true/false
db:close()
```

## Redis (`api.redis`)

Lightweight Redis client using raw RESP protocol over sockets. No additional dependencies required.

### Connecting

```lua
local redis = api.redis.connect({
    host = '127.0.0.1',     -- default
    port = 6379,             -- default
    password = 'secret',     -- optional
    db = 0,                  -- optional, database number
    timeout = 5,             -- optional, connection timeout in seconds
})
```

### String Commands

```lua
redis:set('key', 'value')
redis:set('key', 'value', { ex = 60 })   -- expires in 60 seconds
redis:set('key', 'value', { px = 5000 }) -- expires in 5000 milliseconds

local val = redis:get('key')              -- returns string or nil
redis:del('key')
redis:exists('key')                        -- returns boolean
redis:incr('counter')
redis:decr('counter')
redis:incrby('counter', 5)
redis:append('key', ' more')
```

### Hash Commands

```lua
redis:hset('user:123', 'name', 'Alice')
redis:hget('user:123', 'name')              -- 'Alice'
redis:hgetall('user:123')                    -- { name = 'Alice', ... }
redis:hdel('user:123', 'name')
redis:hexists('user:123', 'name')            -- boolean
redis:hincrby('user:123', 'score', 10)
redis:hkeys('user:123')                      -- array of field names
redis:hvals('user:123')                      -- array of values
redis:hlen('user:123')                       -- field count
```

### List Commands

```lua
redis:lpush('queue', 'item')
redis:rpush('queue', 'item')
redis:lpop('queue')
redis:rpop('queue')
redis:lrange('queue', 0, -1)   -- all items
redis:llen('queue')
```

### Set Commands

```lua
redis:sadd('tags', 'lua')
redis:srem('tags', 'lua')
redis:smembers('tags')           -- array of members
redis:sismember('tags', 'lua')   -- boolean
redis:scard('tags')              -- set size
```

### Sorted Set Commands

```lua
redis:zadd('leaderboard', 100, 'Alice')
redis:zadd('leaderboard', 200, 'Bob')
redis:zscore('leaderboard', 'Alice')            -- 100
redis:zrange('leaderboard', 0, -1)              -- ordered members
redis:zrange('leaderboard', 0, -1, true)        -- with scores
redis:zcard('leaderboard')
redis:zrem('leaderboard', 'Alice')
```

### Key Commands

```lua
redis:expire('key', 120)          -- set TTL in seconds
redis:pexpire('key', 5000)        -- set TTL in milliseconds
redis:ttl('key')                   -- remaining TTL in seconds
redis:pttl('key')                  -- remaining TTL in milliseconds
redis:keys('user:*')               -- matching keys (use sparingly)
redis:type('key')                  -- 'string', 'hash', 'list', etc.
redis:rename('old', 'new')
```

### JSON Helpers

Convenience methods that serialize/deserialize Lua tables as JSON:

```lua
redis:jset('config', { theme = 'dark', lang = 'en' })
redis:jset('session', { user_id = 123 }, { ex = 3600 })

local config = redis:jget('config')  -- { theme = 'dark', lang = 'en' }
```

### Raw Commands

```lua
local result = redis:command('LPOS', 'mylist', 'needle')
```

### Connection Management

```lua
redis:ping()            -- 'PONG'
redis:is_connected()    -- boolean
redis:close()
```

## LLM (`api.llm`)

Unified interface for OpenAI and Anthropic (Claude) APIs. No additional dependencies; uses the built-in HTTP client.

### Creating an Instance

```lua
-- OpenAI
local llm = api.llm.new({
    provider = 'openai',
    api_key = os.getenv('OPENAI_API_KEY'),
    model = 'gpt-4o',                     -- default model
    base_url = 'https://api.openai.com/v1', -- optional, for proxies
    defaults = {                           -- optional default options
        temperature = 0.7,
        max_tokens = 1000,
    },
})

-- Anthropic (Claude)
local llm = api.llm.new({
    provider = 'anthropic',
    api_key = os.getenv('ANTHROPIC_API_KEY'),
    model = 'claude-sonnet-4-5-20250929',
    defaults = { max_tokens = 2048 },
})
```

### Chat

```lua
local result = llm:chat({
    { role = 'user', content = 'What is the capital of France?' }
})

print(result.content)        -- 'The capital of France is Paris.'
print(result.finish_reason)  -- 'stop' or 'end_turn'
print(result.usage.total_tokens)
```

With options:

```lua
local result = llm:chat({
    { role = 'user', content = 'Tell me a joke' }
}, {
    temperature = 0.9,
    max_tokens = 200,
    system = 'You are a comedian.',
})
```

Multi-turn conversation:

```lua
local result = llm:chat({
    { role = 'system', content = 'You are a helpful assistant.' },
    { role = 'user', content = 'What is 2+2?' },
    { role = 'assistant', content = '4' },
    { role = 'user', content = 'And 3+3?' },
})
```

### Complete (Shorthand)

```lua
local result = llm:complete('Translate "hello" to French')
print(result.content)
```

### Embeddings (OpenAI only)

```lua
local result = llm:embed('Hello world')
print(#result.embeddings[1])  -- vector dimension

-- Batch embeddings
local result = llm:embed({'Hello', 'World'})
```

### Error Handling

```lua
local result, err = llm:chat({{ role = 'user', content = 'test' }})
if not result then
    print('LLM error:', err)
end
```

### Example: AI-powered Bot

```lua
local api = require('telegram-bot-lua').configure(os.getenv('BOT_TOKEN'))

local llm = api.llm.new({
    provider = 'anthropic',
    api_key = os.getenv('ANTHROPIC_API_KEY'),
    model = 'claude-sonnet-4-5-20250929',
})

function api.on_message(message)
    if not message.text then return end

    api.send_typing(message.chat.id)

    local result, err = llm:chat({
        { role = 'user', content = message.text }
    }, { system = 'You are a helpful Telegram bot. Keep answers concise.' })

    if result then
        api.send_message(message.chat.id, result.content)
    else
        api.send_message(message.chat.id, 'Sorry, I encountered an error.')
    end
end

api.run({ timeout = 60 })
```

## Email (`api.email`)

SMTP email sending via luasocket (already a dependency).

### Creating an Instance

```lua
local mailer = api.email.new({
    host = 'smtp.gmail.com',
    port = 587,                  -- default
    username = 'bot@gmail.com',
    password = 'app-password',
    tls = true,                  -- default, uses STARTTLS
    domain = 'gmail.com',        -- optional EHLO domain
})
```

### Sending Email

```lua
-- Plain text
mailer:send({
    from = 'bot@gmail.com',
    to = 'user@example.com',
    subject = 'Bot Notification',
    body = 'Something happened in your bot!',
})

-- HTML
mailer:send({
    from = 'bot@gmail.com',
    to = 'user@example.com',
    subject = 'Report',
    html = '<h1>Daily Report</h1><p>All systems normal.</p>',
})

-- Both text and HTML (multipart/alternative)
mailer:send({
    from = 'bot@gmail.com',
    to = 'user@example.com',
    subject = 'Report',
    body = 'Daily Report\nAll systems normal.',
    html = '<h1>Daily Report</h1><p>All systems normal.</p>',
})

-- Multiple recipients and CC
mailer:send({
    from = 'bot@gmail.com',
    to = { 'user1@example.com', 'user2@example.com' },
    cc = 'admin@example.com',
    reply_to = 'noreply@example.com',
    from_name = 'My Bot',
    subject = 'Notification',
    body = 'Hello everyone.',
})
```

### Convenience Methods

```lua
mailer:send_text('bot@gmail.com', 'user@example.com', 'Subject', 'Body')
mailer:send_html('bot@gmail.com', 'user@example.com', 'Subject', '<p>HTML</p>')
```

### Error Handling

```lua
local ok, err = mailer:send({ ... })
if not ok then
    print('Email failed:', err)
end
```

## Async Behavior

All adapters automatically detect whether they're running inside the copas event loop:

- **Inside `api.run()`** (default, async): adapters use non-blocking sockets and HTTP, allowing concurrent operations
- **Outside `api.run()`** or with `api.run({ sync = true })`: adapters use standard blocking I/O

No code changes needed; the same adapter code works in both contexts.
