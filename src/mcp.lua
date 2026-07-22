--- MCP (model context protocol) JSON-RPC server for telegram bot tools.
-- @module telegram-bot-lua.mcp
return function(api)
    local json = require('dkjson')

    api.mcp = {}

    -- JSON-RPC 2.0 helpers. the id member is REQUIRED in responses; when the
    -- request id is unknown (e.g. a parse error) it must be present as null,
    -- so a nil id maps to json.null rather than being dropped by the encoder.
    local function jsonrpc_result(id, result)
        return json.encode({
            jsonrpc = '2.0',
            id = id == nil and json.null or id,
            result = result
        })
    end

    local function jsonrpc_error(id, code, message, data)
        return json.encode({
            jsonrpc = '2.0',
            id = id == nil and json.null or id,
            error = {
                code = code,
                message = message,
                data = data
            }
        })
    end

    -- mark a table so dkjson encodes it as a JSON object even when empty
    -- (MCP capability values and JSON Schema `properties` must be objects,
    -- but dkjson encodes a bare empty lua table as []).
    local function json_object(t)
        return setmetatable(t, { ['__jsontype'] = 'object' })
    end

    -- MCP protocol error codes
    local PARSE_ERROR = -32700
    local INVALID_REQUEST = -32600
    local METHOD_NOT_FOUND = -32601
    local INVALID_PARAMS = -32602
    local INTERNAL_ERROR = -32603

    -- Tool definitions: curated set of high-value Telegram Bot API methods.
    -- Each tool maps to an api method with a JSON Schema for parameters.
    local tool_defs = {
        {
            name = 'send_message',
            description = 'Send a text message to a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Target chat ID or @username' },
                    text = { type = 'string', description = 'Message text' },
                    parse_mode = { type = 'string', description = 'Parse mode: MarkdownV2, HTML, or Markdown' },
                    disable_notification = { type = 'boolean', description = 'Send silently' }
                },
                required = { 'chat_id', 'text' }
            },
            call = function(params)
                return api.send_message(params.chat_id, params.text, {
                    parse_mode = params.parse_mode,
                    disable_notification = params.disable_notification
                })
            end
        },
        {
            name = 'send_photo',
            description = 'Send a photo to a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Target chat ID or @username' },
                    photo = { type = 'string', description = 'Photo file path, URL, or file_id' },
                    caption = { type = 'string', description = 'Photo caption' },
                    parse_mode = { type = 'string', description = 'Parse mode for caption' }
                },
                required = { 'chat_id', 'photo' }
            },
            call = function(params)
                return api.send_photo(params.chat_id, params.photo, {
                    caption = params.caption,
                    parse_mode = params.parse_mode
                })
            end
        },
        {
            name = 'get_updates',
            description = 'Get recent updates (messages, callbacks, etc.)',
            inputSchema = {
                type = 'object',
                properties = {
                    limit = { type = 'number', description = 'Max number of updates (1-100)' },
                    timeout = { type = 'number', description = 'Long polling timeout in seconds' },
                    offset = { type = 'number', description = 'Update offset' }
                }
            },
            call = function(params)
                return api.get_updates({
                    limit = params.limit,
                    timeout = params.timeout,
                    offset = params.offset
                })
            end
        },
        {
            name = 'get_me',
            description = 'Get basic info about the bot',
            inputSchema = {
                type = 'object',
                properties = json_object({})
            },
            call = function(_)
                return api.get_me()
            end
        },
        {
            name = 'get_chat',
            description = 'Get information about a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID or @username' }
                },
                required = { 'chat_id' }
            },
            call = function(params)
                return api.get_chat(params.chat_id)
            end
        },
        {
            name = 'get_chat_member',
            description = 'Get info about a chat member',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID or @username' },
                    user_id = { type = 'number', description = 'User ID' }
                },
                required = { 'chat_id', 'user_id' }
            },
            call = function(params)
                return api.get_chat_member(params.chat_id, params.user_id)
            end
        },
        {
            name = 'get_chat_member_count',
            description = 'Get the number of members in a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID or @username' }
                },
                required = { 'chat_id' }
            },
            call = function(params)
                return api.get_chat_member_count(params.chat_id)
            end
        },
        {
            name = 'ban_chat_member',
            description = 'Ban a user from a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID or @username' },
                    user_id = { type = 'number', description = 'User ID to ban' },
                    until_date = { type = 'number', description = 'Ban end date (Unix timestamp)' },
                    revoke_messages = { type = 'boolean', description = 'Delete all messages from the user' }
                },
                required = { 'chat_id', 'user_id' }
            },
            call = function(params)
                return api.ban_chat_member(params.chat_id, params.user_id, {
                    until_date = params.until_date,
                    revoke_messages = params.revoke_messages
                })
            end
        },
        {
            name = 'unban_chat_member',
            description = 'Unban a user from a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID or @username' },
                    user_id = { type = 'number', description = 'User ID to unban' },
                    only_if_banned = { type = 'boolean', description = 'Only unban if currently banned' }
                },
                required = { 'chat_id', 'user_id' }
            },
            call = function(params)
                return api.unban_chat_member(params.chat_id, params.user_id, {
                    only_if_banned = params.only_if_banned
                })
            end
        },
        {
            name = 'delete_message',
            description = 'Delete a message',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID' },
                    message_id = { type = 'number', description = 'Message ID to delete' }
                },
                required = { 'chat_id', 'message_id' }
            },
            call = function(params)
                return api.delete_message(params.chat_id, params.message_id)
            end
        },
        {
            name = 'pin_chat_message',
            description = 'Pin a message in a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID' },
                    message_id = { type = 'number', description = 'Message ID to pin' },
                    disable_notification = { type = 'boolean', description = 'Pin silently' }
                },
                required = { 'chat_id', 'message_id' }
            },
            call = function(params)
                return api.pin_chat_message(params.chat_id, params.message_id, {
                    disable_notification = params.disable_notification
                })
            end
        },
        {
            name = 'unpin_chat_message',
            description = 'Unpin a message in a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID' },
                    message_id = { type = 'number', description = 'Message ID to unpin' }
                },
                required = { 'chat_id' }
            },
            call = function(params)
                return api.unpin_chat_message(params.chat_id, {
                    message_id = params.message_id
                })
            end
        },
        {
            name = 'answer_callback_query',
            description = 'Answer a callback query from an inline button',
            inputSchema = {
                type = 'object',
                properties = {
                    callback_query_id = { type = 'string', description = 'Callback query ID' },
                    text = { type = 'string', description = 'Notification text' },
                    show_alert = { type = 'boolean', description = 'Show alert instead of notification' }
                },
                required = { 'callback_query_id' }
            },
            call = function(params)
                return api.answer_callback_query(params.callback_query_id, {
                    text = params.text,
                    show_alert = params.show_alert
                })
            end
        },
        {
            name = 'edit_message_text',
            description = 'Edit the text of a message',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID' },
                    message_id = { type = 'number', description = 'Message ID to edit' },
                    text = { type = 'string', description = 'New text' },
                    parse_mode = { type = 'string', description = 'Parse mode' }
                },
                required = { 'chat_id', 'message_id', 'text' }
            },
            call = function(params)
                return api.edit_message_text(params.chat_id, params.message_id, params.text, {
                    parse_mode = params.parse_mode
                })
            end
        },
        {
            name = 'forward_message',
            description = 'Forward a message from one chat to another',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Target chat ID' },
                    from_chat_id = { type = 'string', description = 'Source chat ID' },
                    message_id = { type = 'number', description = 'Message ID to forward' },
                    disable_notification = { type = 'boolean', description = 'Forward silently' }
                },
                required = { 'chat_id', 'from_chat_id', 'message_id' }
            },
            call = function(params)
                return api.forward_message(params.chat_id, params.from_chat_id, params.message_id, {
                    disable_notification = params.disable_notification
                })
            end
        },
        {
            name = 'send_document',
            description = 'Send a document/file to a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Target chat ID' },
                    document = { type = 'string', description = 'Document file path, URL, or file_id' },
                    caption = { type = 'string', description = 'Document caption' },
                    parse_mode = { type = 'string', description = 'Parse mode for caption' }
                },
                required = { 'chat_id', 'document' }
            },
            call = function(params)
                return api.send_document(params.chat_id, params.document, {
                    caption = params.caption,
                    parse_mode = params.parse_mode
                })
            end
        },
        {
            name = 'set_chat_title',
            description = 'Set the title of a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID' },
                    title = { type = 'string', description = 'New chat title' }
                },
                required = { 'chat_id', 'title' }
            },
            call = function(params)
                return api.set_chat_title(params.chat_id, params.title)
            end
        },
        {
            name = 'set_chat_description',
            description = 'Set the description of a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID' },
                    description = { type = 'string', description = 'New chat description' }
                },
                required = { 'chat_id' }
            },
            call = function(params)
                return api.set_chat_description(params.chat_id, {
                    description = params.description
                })
            end
        },
        {
            name = 'leave_chat',
            description = 'Leave a chat',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID to leave' }
                },
                required = { 'chat_id' }
            },
            call = function(params)
                return api.leave_chat(params.chat_id)
            end
        },
        {
            name = 'get_chat_administrators',
            description = 'Get a list of chat administrators',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID or @username' }
                },
                required = { 'chat_id' }
            },
            call = function(params)
                return api.get_chat_administrators(params.chat_id)
            end
        },
        {
            name = 'send_location',
            description = 'Send a location point on the map',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Target chat ID' },
                    latitude = { type = 'number', description = 'Latitude' },
                    longitude = { type = 'number', description = 'Longitude' }
                },
                required = { 'chat_id', 'latitude', 'longitude' }
            },
            call = function(params)
                return api.send_location(params.chat_id, params.latitude, params.longitude)
            end
        },
        {
            name = 'send_contact',
            description = 'Send a phone contact',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Target chat ID' },
                    phone_number = { type = 'string', description = 'Phone number' },
                    first_name = { type = 'string', description = 'Contact first name' },
                    last_name = { type = 'string', description = 'Contact last name' }
                },
                required = { 'chat_id', 'phone_number', 'first_name' }
            },
            call = function(params)
                return api.send_contact(params.chat_id, params.phone_number, params.first_name, {
                    last_name = params.last_name
                })
            end
        },
        {
            name = 'restrict_chat_member',
            description = 'Restrict a chat member permissions',
            inputSchema = {
                type = 'object',
                properties = {
                    chat_id = { type = 'string', description = 'Chat ID' },
                    user_id = { type = 'number', description = 'User ID to restrict' },
                    permissions = { type = 'object', description = 'New permissions object' },
                    until_date = { type = 'number', description = 'Restriction end date (Unix timestamp)' }
                },
                required = { 'chat_id', 'user_id', 'permissions' }
            },
            call = function(params)
                return api.restrict_chat_member(params.chat_id, params.user_id, params.permissions, {
                    until_date = params.until_date
                })
            end
        }
    }

    -- Build tool lookup by name
    local tool_lookup = {}
    for _, tool in ipairs(tool_defs) do
        tool_lookup[tool.name] = tool
    end

    -- Resource definitions
    local resource_defs = {
        {
            uri = 'telegram://bot/info',
            name = 'Bot Info',
            description = 'Basic information about the bot (username, ID, capabilities)',
            mimeType = 'application/json'
        }
    }

    -- MCP protocol version
    local PROTOCOL_VERSION = '2024-11-05'

    --- handle a single MCP JSON-RPC request and return the response string.
    -- @param request string|table a JSON string or decoded request table
    -- @return string JSON-RPC response, or nil for notifications
    function api.mcp.handle(request)
        if type(request) == 'string' then
            local ok, parsed = pcall(json.decode, request)
            if not ok or not parsed then
                return jsonrpc_error(nil, PARSE_ERROR, 'Parse error')
            end
            request = parsed
        end

        if type(request) ~= 'table' then
            return jsonrpc_error(nil, INVALID_REQUEST, 'Invalid request')
        end

        local id = request.id
        local method = request.method

        if not method or type(method) ~= 'string' then
            return jsonrpc_error(id, INVALID_REQUEST, 'Invalid request: missing method')
        end

        -- Notifications (no id) — a JSON-RPC request without an id is a
        -- notification and MUST NOT be answered, whatever its method.
        if id == nil then
            return nil
        end

        -- params must be a table; a scalar params member is malformed and
        -- must not crash the handler with an index error.
        local params = type(request.params) == 'table' and request.params or {}

        if method == 'initialize' then
            return jsonrpc_result(id, {
                protocolVersion = PROTOCOL_VERSION,
                capabilities = {
                    tools = json_object({}),
                    resources = json_object({})
                },
                serverInfo = {
                    name = 'telegram-bot-lua',
                    version = api.version or 'unknown'
                }
            })

        elseif method == 'tools/list' then
            local tools = {}
            for _, tool in ipairs(tool_defs) do
                tools[#tools + 1] = {
                    name = tool.name,
                    description = tool.description,
                    inputSchema = tool.inputSchema
                }
            end
            return jsonrpc_result(id, { tools = tools })

        elseif method == 'tools/call' then
            local tool_name = params.name
            local tool_args = params.arguments or {}

            if not tool_name or not tool_lookup[tool_name] then
                return jsonrpc_error(id, METHOD_NOT_FOUND, 'Tool not found: ' .. tostring(tool_name))
            end

            local tool = tool_lookup[tool_name]

            -- Validate required params
            local schema = tool.inputSchema
            if schema and schema.required then
                for _, req_param in ipairs(schema.required) do
                    if tool_args[req_param] == nil then
                        return jsonrpc_error(id, INVALID_PARAMS,
                            'Missing required parameter: ' .. req_param)
                    end
                end
            end

            local ok, result = pcall(tool.call, tool_args)
            if not ok then
                return jsonrpc_error(id, INTERNAL_ERROR, 'Tool execution error: ' .. tostring(result))
            end

            -- Format result as MCP content
            local content
            if result and type(result) == 'table' then
                content = { { type = 'text', text = json.encode(result) } }
            else
                content = { { type = 'text', text = tostring(result) } }
            end

            return jsonrpc_result(id, {
                content = content,
                isError = not result
            })

        elseif method == 'resources/list' then
            local resources = {}
            for _, res in ipairs(resource_defs) do
                resources[#resources + 1] = {
                    uri = res.uri,
                    name = res.name,
                    description = res.description,
                    mimeType = res.mimeType
                }
            end
            return jsonrpc_result(id, { resources = resources })

        elseif method == 'resources/read' then
            local uri = params.uri
            if not uri then
                return jsonrpc_error(id, INVALID_PARAMS, 'Missing required parameter: uri')
            end

            if uri == 'telegram://bot/info' then
                local info = api.info or {}
                return jsonrpc_result(id, {
                    contents = {
                        {
                            uri = uri,
                            mimeType = 'application/json',
                            text = json.encode(info)
                        }
                    }
                })
            end

            return jsonrpc_error(id, METHOD_NOT_FOUND, 'Resource not found: ' .. uri)

        elseif method == 'ping' then
            return jsonrpc_result(id, json_object({}))

        else
            return jsonrpc_error(id, METHOD_NOT_FOUND, 'Method not found: ' .. method)
        end
    end

    --- run the MCP server over stdio.
    -- reads JSON-RPC messages line by line from stdin and writes responses to stdout.
    -- @param opts table optional overrides for input/output streams
    -- @param opts.input file input stream (default io.stdin)
    -- @param opts.write function write function (default io.write)
    -- @param opts.flush function flush function (default io.flush)
    function api.mcp.serve(opts)
        opts = opts or {}
        local input = opts.input or io.stdin
        local write = opts.write or io.write
        local flush = opts.flush or io.flush

        for line in input:lines() do
            if line ~= '' then
                local response = api.mcp.handle(line)
                if response then
                    write(response .. '\n')
                    flush()
                end
            end
        end
    end
end
