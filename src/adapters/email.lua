--- email (SMTP) adapter for sending mail via luasocket.
-- @module telegram-bot-lua.adapters.email
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

        -- with cc and reply-to
        mailer:send({
            from = 'bot@gmail.com',
            to = 'user@example.com',
            cc = 'admin@example.com',
            reply_to = 'noreply@example.com',
            subject = 'Notification',
            body = 'Bot message.',
        })

        -- with attachments (multipart/mixed)
        mailer:send({
            from = 'bot@gmail.com',
            to = 'user@example.com',
            subject = 'Your report',
            body = 'See attached.',
            attachments = {
                { filename = 'report.csv', content = 'a,b\n1,2\n',
                  content_type = 'text/csv' },
            },
        })
]]

return function(api)
    api.email = {}

    --- create a new email sender instance.
    -- @param opts table SMTP configuration options
    -- @param opts.host string SMTP server hostname
    -- @param opts.port number SMTP port (default 587)
    -- @param opts.username string SMTP username
    -- @param opts.password string SMTP password
    -- @param opts.tls boolean enable STARTTLS (default true)
    -- @return table email instance with send, send_text, send_html methods
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

            -- header values are caller-supplied; strip CR/LF so a crafted
            -- subject/address cannot inject additional headers (e.g. Bcc).
            local function header_safe(value)
                return (tostring(value):gsub('[\r\n]', ' '))
            end

            -- Normalize recipients to a NEW table: aliasing msg.to and
            -- appending CC entries used to mutate the caller's table and leak
            -- CC addresses into the To: header.
            local rcpt = {}
            if type(msg.to) == 'string' then
                rcpt[1] = msg.to
            else
                for _, addr in ipairs(msg.to) do
                    rcpt[#rcpt + 1] = addr
                end
            end

            -- Add CC recipients (envelope only; the Cc: header is separate)
            if msg.cc then
                local cc_list = type(msg.cc) == 'string' and { msg.cc } or msg.cc
                for _, addr in ipairs(cc_list) do
                    rcpt[#rcpt + 1] = addr
                end
            end

            -- Build headers
            local headers = {
                ['From'] = header_safe(msg.from_name and ('"' .. msg.from_name .. '" <' .. msg.from .. '>') or msg.from),
                ['To'] = header_safe(type(msg.to) == 'table' and table.concat(msg.to, ', ') or msg.to),
                ['Subject'] = header_safe(msg.subject),
                ['Date'] = os.date('!%a, %d %b %Y %H:%M:%S +0000'),
                ['MIME-Version'] = '1.0',
            }

            if msg.cc then
                headers['Cc'] = header_safe(type(msg.cc) == 'table' and table.concat(msg.cc, ', ') or msg.cc)
            end

            if msg.reply_to then
                headers['Reply-To'] = header_safe(msg.reply_to)
            end

            -- MIME boundaries must not be able to collide with message
            -- content; hard-coded names could be terminated early by a body
            -- line that happened to match.
            local boundary_seq = 0
            local function unique_boundary(tag)
                boundary_seq = boundary_seq + 1
                return string.format('=_%s_%d_%d_%d', tag, os.time(), math.random(1e9), boundary_seq)
            end

            -- encode content as quoted-printable (with newline normalization)
            -- so the declared Content-Transfer-Encoding matches what is sent.
            local function qp_encode(data)
                local mime = require('mime')
                local filter = ltn12.filter.chain(mime.normalize(), mime.encode('quoted-printable'))
                local parts = {}
                parts[#parts + 1] = filter(data)
                parts[#parts + 1] = filter(nil) -- flush any buffered tail
                return table.concat(parts)
            end

            -- render the body part as a self-contained mime entity: its own
            -- content-type plus the encoded body. this is reused as-is whether
            -- the message is sent on its own or nested inside multipart/mixed.
            local function render_body_part()
                if msg.html and msg.body then
                    local boundary = unique_boundary('alt')
                    local content_type = 'multipart/alternative; boundary="' .. boundary .. '"'
                    local part = '--' .. boundary .. '\r\n'
                        .. 'Content-Type: text/plain; charset=UTF-8\r\n'
                        .. 'Content-Transfer-Encoding: quoted-printable\r\n\r\n'
                        .. qp_encode(msg.body) .. '\r\n'
                        .. '--' .. boundary .. '\r\n'
                        .. 'Content-Type: text/html; charset=UTF-8\r\n'
                        .. 'Content-Transfer-Encoding: quoted-printable\r\n\r\n'
                        .. qp_encode(msg.html) .. '\r\n'
                        .. '--' .. boundary .. '--\r\n'
                    return content_type, part
                elseif msg.html then
                    return 'text/html; charset=UTF-8', msg.html
                else
                    return 'text/plain; charset=UTF-8', msg.body
                end
            end

            -- serialise the top-level headers, applying an explicit content-type.
            local function render_headers(content_type)
                headers['Content-Type'] = content_type
                local header_str = ''
                for k, v in pairs(headers) do
                    header_str = header_str .. k .. ': ' .. v .. '\r\n'
                end
                return header_str
            end

            -- base64-encode a string in fixed-width lines per rfc 2045.
            local function base64_lines(data)
                local mime = require('mime')
                local encoded = (mime.b64(data))
                local wrapped = {}
                for i = 1, #encoded, 76 do
                    wrapped[#wrapped + 1] = encoded:sub(i, i + 75)
                end
                return table.concat(wrapped, '\r\n')
            end

            local body_content_type, body_part = render_body_part()

            -- build message body
            local message_source
            if msg.attachments and #msg.attachments > 0 then
                -- wrap the body part and every attachment in multipart/mixed.
                local boundary = unique_boundary('mixed')
                local mixed = '--' .. boundary .. '\r\n'
                    .. 'Content-Type: ' .. body_content_type .. '\r\n\r\n'
                    .. body_part .. '\r\n'
                for _, att in ipairs(msg.attachments) do
                    local filename = att.filename or 'attachment'
                    local ctype = att.content_type or 'application/octet-stream'
                    mixed = mixed
                        .. '--' .. boundary .. '\r\n'
                        .. 'Content-Type: ' .. ctype .. '; name="' .. filename .. '"\r\n'
                        .. 'Content-Transfer-Encoding: base64\r\n'
                        .. 'Content-Disposition: attachment; filename="' .. filename .. '"\r\n\r\n'
                        .. base64_lines(att.content or '') .. '\r\n'
                end
                mixed = mixed .. '--' .. boundary .. '--\r\n'

                local header_str = render_headers(
                    'multipart/mixed; boundary="' .. boundary .. '"')
                message_source = ltn12.source.string(header_str .. '\r\n' .. mixed)
            else
                local header_str = render_headers(body_content_type)
                message_source = ltn12.source.string(header_str .. '\r\n' .. body_part)
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
                if not ok_ssl and api.log then
                    api.log.warn('email: tls requested but the ssl (luasec) module is unavailable; ' ..
                        'credentials will be sent without STARTTLS')
                end
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
