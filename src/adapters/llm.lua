--[[
    LLM adapter for telegram-bot-lua.
    Provides a unified interface for OpenAI and Anthropic APIs.
    Async-first: uses non-blocking HTTP inside copas, sync fallback otherwise.

    Usage:
        local llm = api.llm.new({
            provider = 'openai',
            api_key = 'sk-...',
            model = 'gpt-4o',
        })
        -- or
        local llm = api.llm.new({
            provider = 'anthropic',
            api_key = 'sk-ant-...',
            model = 'claude-sonnet-4-5-20250929',
        })

        local response = llm:chat({
            { role = 'user', content = 'Hello!' }
        })
        -- response.content   -- the text response
        -- response.usage     -- token usage info

        local response = llm:chat({
            { role = 'user', content = 'What is 2+2?' }
        }, { temperature = 0.5, max_tokens = 100 })
]]

return function(api)
    api.llm = {}

    local json = require('dkjson')

    -- HTTP request helper that works in both sync and async contexts
    local function http_request(url, opts)
        return api.adapters.http_request(url, opts)
    end

    function api.llm.new(opts)
        assert(opts and opts.provider, 'llm.new requires a provider option (openai, anthropic)')
        assert(opts.api_key, 'llm.new requires an api_key option')

        local provider = opts.provider:lower()

        if provider == 'openai' then
            return api.llm._new_openai(opts)
        elseif provider == 'anthropic' or provider == 'claude' then
            return api.llm._new_anthropic(opts)
        else
            error('Unsupported LLM provider: ' .. tostring(opts.provider) .. '. Supported: openai, anthropic')
        end
    end

    -- OpenAI-compatible provider --

    function api.llm._new_openai(opts)
        local instance = {
            _provider = 'openai',
            _api_key = opts.api_key,
            _model = opts.model or 'gpt-4o',
            _base_url = opts.base_url or 'https://api.openai.com/v1',
            _default_opts = opts.defaults or {},
        }

        function instance:chat(messages, chat_opts)
            chat_opts = chat_opts or {}
            local request_body = {
                model = chat_opts.model or self._model,
                messages = messages,
                temperature = chat_opts.temperature or self._default_opts.temperature,
                max_tokens = chat_opts.max_tokens or self._default_opts.max_tokens,
                top_p = chat_opts.top_p or self._default_opts.top_p,
                frequency_penalty = chat_opts.frequency_penalty,
                presence_penalty = chat_opts.presence_penalty,
                stop = chat_opts.stop,
            }

            -- Add system message if provided
            if chat_opts.system then
                table.insert(messages, 1, { role = 'system', content = chat_opts.system })
            end

            local body = json.encode(request_body)
            local response, status = http_request(self._base_url .. '/chat/completions', {
                method = 'POST',
                headers = {
                    ['Content-Type'] = 'application/json',
                    ['Authorization'] = 'Bearer ' .. self._api_key,
                },
                body = body,
            })

            if not response then
                return nil, 'HTTP request failed: ' .. tostring(status)
            end

            local data = json.decode(response)
            if not data then
                return nil, 'Failed to parse response JSON'
            end

            if data.error then
                return nil, data.error.message or 'OpenAI API error'
            end

            local choice = data.choices and data.choices[1]
            if not choice then
                return nil, 'No response choices returned'
            end

            return {
                content = choice.message and choice.message.content or '',
                role = choice.message and choice.message.role or 'assistant',
                finish_reason = choice.finish_reason,
                usage = data.usage and {
                    prompt_tokens = data.usage.prompt_tokens,
                    completion_tokens = data.usage.completion_tokens,
                    total_tokens = data.usage.total_tokens,
                },
                raw = data,
            }
        end

        function instance:complete(prompt, complete_opts)
            return self:chat({{ role = 'user', content = prompt }}, complete_opts)
        end

        function instance:embed(input, embed_opts)
            embed_opts = embed_opts or {}
            local request_body = {
                model = embed_opts.model or 'text-embedding-3-small',
                input = input,
            }

            local body = json.encode(request_body)
            local response, status = http_request(self._base_url .. '/embeddings', {
                method = 'POST',
                headers = {
                    ['Content-Type'] = 'application/json',
                    ['Authorization'] = 'Bearer ' .. self._api_key,
                },
                body = body,
            })

            if not response then
                return nil, 'HTTP request failed: ' .. tostring(status)
            end

            local data = json.decode(response)
            if not data then
                return nil, 'Failed to parse response JSON'
            end

            if data.error then
                return nil, data.error.message or 'OpenAI API error'
            end

            local vectors = {}
            if data.data then
                for _, item in ipairs(data.data) do
                    vectors[#vectors + 1] = item.embedding
                end
            end

            return {
                embeddings = vectors,
                usage = data.usage,
                raw = data,
            }
        end

        return instance
    end

    -- Anthropic (Claude) provider --

    function api.llm._new_anthropic(opts)
        local instance = {
            _provider = 'anthropic',
            _api_key = opts.api_key,
            _model = opts.model or 'claude-sonnet-4-5-20250929',
            _base_url = opts.base_url or 'https://api.anthropic.com/v1',
            _default_opts = opts.defaults or {},
        }

        function instance:chat(messages, chat_opts)
            chat_opts = chat_opts or {}

            -- Extract system message if present
            local system_msg = chat_opts.system
            local filtered_messages = {}
            for _, msg in ipairs(messages) do
                if msg.role == 'system' then
                    system_msg = system_msg or msg.content
                else
                    filtered_messages[#filtered_messages + 1] = msg
                end
            end

            local request_body = {
                model = chat_opts.model or self._model,
                messages = filtered_messages,
                max_tokens = chat_opts.max_tokens or self._default_opts.max_tokens or 1024,
                temperature = chat_opts.temperature or self._default_opts.temperature,
                top_p = chat_opts.top_p or self._default_opts.top_p,
                stop_sequences = chat_opts.stop,
            }

            if system_msg then
                request_body.system = system_msg
            end

            local body = json.encode(request_body)
            local response, status = http_request(self._base_url .. '/messages', {
                method = 'POST',
                headers = {
                    ['Content-Type'] = 'application/json',
                    ['x-api-key'] = self._api_key,
                    ['anthropic-version'] = '2023-06-01',
                },
                body = body,
            })

            if not response then
                return nil, 'HTTP request failed: ' .. tostring(status)
            end

            local data = json.decode(response)
            if not data then
                return nil, 'Failed to parse response JSON'
            end

            if data.error then
                return nil, data.error.message or 'Anthropic API error'
            end

            -- Extract text content from content blocks
            local text_parts = {}
            if data.content then
                for _, block in ipairs(data.content) do
                    if block.type == 'text' then
                        text_parts[#text_parts + 1] = block.text
                    end
                end
            end

            return {
                content = table.concat(text_parts, ''),
                role = data.role or 'assistant',
                finish_reason = data.stop_reason,
                usage = data.usage and {
                    prompt_tokens = data.usage.input_tokens,
                    completion_tokens = data.usage.output_tokens,
                    total_tokens = (data.usage.input_tokens or 0) + (data.usage.output_tokens or 0),
                },
                raw = data,
            }
        end

        function instance:complete(prompt, complete_opts)
            return self:chat({{ role = 'user', content = prompt }}, complete_opts)
        end

        return instance
    end
end
