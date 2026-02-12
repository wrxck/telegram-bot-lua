--[[
    Email (SMTP) adapter for telegram-bot-lua.
    Sends email via SMTP using luasocket's smtp module.
    Async-first: uses copas when available for non-blocking sends.

    Usage:
        local mailer = api.email.new({
            host = 'smtp.gmail.com',
            port = 587,
            username = 'bot@gmail.com',
            password = 'app-password',
            tls = true,
        })

        mailer:send({
            from = 'bot@gmail.com',
            to = 'user@example.com',
            subject = 'Hello from your Telegram bot!',
            body = 'This is a notification from your bot.',
        })

        -- HTML email
        mailer:send({
            from = 'bot@gmail.com',
            to = { 'user1@example.com', 'user2@example.com' },
            subject = 'Report',
            html = '<h1>Report</h1><p>Everything is fine.</p>',
        })

        -- With CC and reply-to
        mailer:send({
            from = 'bot@gmail.com',
            to = 'user@example.com',
            cc = 'admin@example.com',
            reply_to = 'noreply@example.com',
            subject = 'Notification',
            body = 'Bot message.',
        })
]]

return function(api)
    api.email = {}

    function api.email.new(opts)
        assert(opts and opts.host, 'email.new requires a host option')

        local instance = {
            _host = opts.host,
            _port = opts.port or 587,
            _username = opts.username,
            _password = opts.password,
            _tls = opts.tls ~= false, -- default true
            _domain = opts.domain or opts.host,
        }

        function instance:send(msg)
            assert(msg.from, 'Email requires a from address')
            assert(msg.to, 'Email requires a to address')
            assert(msg.subject, 'Email requires a subject')
            assert(msg.body or msg.html, 'Email requires a body or html content')

            local smtp = require('socket.smtp')
            local ltn12 = require('ltn12')

            -- Normalize recipients to table
            local rcpt = msg.to
            if type(rcpt) == 'string' then
                rcpt = { rcpt }
            end

            -- Add CC recipients
            if msg.cc then
                local cc_list = type(msg.cc) == 'string' and { msg.cc } or msg.cc
                for _, addr in ipairs(cc_list) do
                    rcpt[#rcpt + 1] = addr
                end
            end

            -- Build headers
            local headers = {
                ['From'] = msg.from_name and ('"' .. msg.from_name .. '" <' .. msg.from .. '>') or msg.from,
                ['To'] = type(msg.to) == 'table' and table.concat(msg.to, ', ') or msg.to,
                ['Subject'] = msg.subject,
                ['Date'] = os.date('!%a, %d %b %Y %H:%M:%S +0000'),
                ['MIME-Version'] = '1.0',
            }

            if msg.cc then
                headers['Cc'] = type(msg.cc) == 'table' and table.concat(msg.cc, ', ') or msg.cc
            end

            if msg.reply_to then
                headers['Reply-To'] = msg.reply_to
            end

            -- Build message body
            local message_source
            if msg.html and msg.body then
                -- Multipart alternative: both text and HTML
                headers['Content-Type'] = 'multipart/alternative; boundary="boundary_tbl"'
                local parts = '--boundary_tbl\r\n'
                    .. 'Content-Type: text/plain; charset=UTF-8\r\n'
                    .. 'Content-Transfer-Encoding: quoted-printable\r\n\r\n'
                    .. msg.body .. '\r\n'
                    .. '--boundary_tbl\r\n'
                    .. 'Content-Type: text/html; charset=UTF-8\r\n'
                    .. 'Content-Transfer-Encoding: quoted-printable\r\n\r\n'
                    .. msg.html .. '\r\n'
                    .. '--boundary_tbl--\r\n'

                -- Build header string
                local header_str = ''
                for k, v in pairs(headers) do
                    header_str = header_str .. k .. ': ' .. v .. '\r\n'
                end
                message_source = ltn12.source.string(header_str .. '\r\n' .. parts)
            elseif msg.html then
                headers['Content-Type'] = 'text/html; charset=UTF-8'
                local header_str = ''
                for k, v in pairs(headers) do
                    header_str = header_str .. k .. ': ' .. v .. '\r\n'
                end
                message_source = ltn12.source.string(header_str .. '\r\n' .. msg.html)
            else
                headers['Content-Type'] = 'text/plain; charset=UTF-8'
                local header_str = ''
                for k, v in pairs(headers) do
                    header_str = header_str .. k .. ': ' .. v .. '\r\n'
                end
                message_source = ltn12.source.string(header_str .. '\r\n' .. msg.body)
            end

            -- Build the send parameters
            local send_params = {
                from = '<' .. msg.from .. '>',
                rcpt = {},
                source = message_source,
                server = self._host,
                port = self._port,
                user = self._username,
                password = self._password,
                domain = self._domain,
            }

            for _, addr in ipairs(rcpt) do
                send_params.rcpt[#send_params.rcpt + 1] = '<' .. addr .. '>'
            end

            -- Use STARTTLS if configured
            if self._tls then
                -- For STARTTLS on port 587, we need to use the create function
                local ok_ssl = pcall(require, 'ssl')
                if ok_ssl then
                    send_params.create = function()
                        local socket_lib = require('socket')
                        local sock = socket_lib.tcp()
                        -- If in async context, wrap with copas
                        if api.adapters.is_async() then
                            local copas = require('copas')
                            sock = copas.wrap(sock, { mode = 'starttls' })
                        end
                        return sock
                    end
                end
            end

            local result, err = smtp.send(send_params)
            if not result then
                return false, 'SMTP send failed: ' .. tostring(err)
            end
            return true
        end

        -- Convenience method for plain text email
        function instance:send_text(from, to, subject, body)
            return self:send({
                from = from,
                to = to,
                subject = subject,
                body = body,
            })
        end

        -- Convenience method for HTML email
        function instance:send_html(from, to, subject, html)
            return self:send({
                from = from,
                to = to,
                subject = subject,
                html = html,
            })
        end

        return instance
    end
end
