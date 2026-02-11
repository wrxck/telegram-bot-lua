local api = require('spec.test_helper')

describe('email adapter', function()
    describe('module', function()
        it('api.email exists', function()
            assert.is_table(api.email)
        end)

        it('has new function', function()
            assert.is_function(api.email.new)
        end)

        it('requires host option', function()
            assert.has_error(function()
                api.email.new({})
            end)
        end)
    end)

    describe('instance', function()
        local mailer

        before_each(function()
            mailer = api.email.new({
                host = 'smtp.example.com',
                port = 587,
                username = 'bot@example.com',
                password = 'secret',
            })
        end)

        it('creates instance', function()
            assert.is_truthy(mailer)
            assert.equals('smtp.example.com', mailer._host)
            assert.equals(587, mailer._port)
        end)

        it('has send method', function()
            assert.is_function(mailer.send)
        end)

        it('has send_text convenience method', function()
            assert.is_function(mailer.send_text)
        end)

        it('has send_html convenience method', function()
            assert.is_function(mailer.send_html)
        end)

        it('defaults to TLS enabled', function()
            assert.is_true(mailer._tls)
        end)

        it('allows disabling TLS', function()
            local notls = api.email.new({
                host = 'smtp.example.com',
                tls = false,
            })
            assert.is_false(notls._tls)
        end)

        it('uses default port 587', function()
            local default_port = api.email.new({
                host = 'smtp.example.com',
            })
            assert.equals(587, default_port._port)
        end)
    end)

    describe('validation', function()
        local mailer

        before_each(function()
            mailer = api.email.new({
                host = 'smtp.example.com',
                username = 'bot@example.com',
                password = 'secret',
            })
        end)

        it('requires from address', function()
            assert.has_error(function()
                mailer:send({
                    to = 'user@example.com',
                    subject = 'Test',
                    body = 'Hello',
                })
            end)
        end)

        it('requires to address', function()
            assert.has_error(function()
                mailer:send({
                    from = 'bot@example.com',
                    subject = 'Test',
                    body = 'Hello',
                })
            end)
        end)

        it('requires subject', function()
            assert.has_error(function()
                mailer:send({
                    from = 'bot@example.com',
                    to = 'user@example.com',
                    body = 'Hello',
                })
            end)
        end)

        it('requires body or html', function()
            assert.has_error(function()
                mailer:send({
                    from = 'bot@example.com',
                    to = 'user@example.com',
                    subject = 'Test',
                })
            end)
        end)

        it('accepts html instead of body', function()
            -- This will fail at SMTP level but should pass validation
            local ok, err = pcall(function()
                mailer:send({
                    from = 'bot@example.com',
                    to = 'user@example.com',
                    subject = 'Test',
                    html = '<p>Hello</p>',
                })
            end)
            -- We expect SMTP connection failure, not validation error
            if not ok then
                assert.truthy(tostring(err):find('SMTP') or tostring(err):find('connect') or tostring(err):find('socket') or tostring(err):find('closed'))
            end
        end)
    end)

    describe('message building', function()
        local mailer
        local captured_params
        local original_smtp_send

        before_each(function()
            mailer = api.email.new({
                host = 'smtp.example.com',
                port = 587,
                username = 'bot@example.com',
                password = 'secret',
            })

            -- Mock smtp.send to capture parameters
            local smtp = require('socket.smtp')
            original_smtp_send = smtp.send
            smtp.send = function(params)
                captured_params = params
                return true
            end
        end)

        after_each(function()
            local smtp = require('socket.smtp')
            smtp.send = original_smtp_send
        end)

        it('sets from correctly', function()
            mailer:send({
                from = 'bot@example.com',
                to = 'user@example.com',
                subject = 'Test',
                body = 'Hello',
            })
            assert.equals('<bot@example.com>', captured_params.from)
        end)

        it('sets single recipient', function()
            mailer:send({
                from = 'bot@example.com',
                to = 'user@example.com',
                subject = 'Test',
                body = 'Hello',
            })
            assert.equals(1, #captured_params.rcpt)
            assert.equals('<user@example.com>', captured_params.rcpt[1])
        end)

        it('sets multiple recipients', function()
            mailer:send({
                from = 'bot@example.com',
                to = { 'user1@example.com', 'user2@example.com' },
                subject = 'Test',
                body = 'Hello',
            })
            assert.equals(2, #captured_params.rcpt)
            assert.equals('<user1@example.com>', captured_params.rcpt[1])
            assert.equals('<user2@example.com>', captured_params.rcpt[2])
        end)

        it('includes CC in recipients', function()
            mailer:send({
                from = 'bot@example.com',
                to = 'user@example.com',
                cc = 'admin@example.com',
                subject = 'Test',
                body = 'Hello',
            })
            assert.equals(2, #captured_params.rcpt)
            assert.equals('<user@example.com>', captured_params.rcpt[1])
            assert.equals('<admin@example.com>', captured_params.rcpt[2])
        end)

        it('includes multiple CC recipients', function()
            mailer:send({
                from = 'bot@example.com',
                to = 'user@example.com',
                cc = { 'admin1@example.com', 'admin2@example.com' },
                subject = 'Test',
                body = 'Hello',
            })
            assert.equals(3, #captured_params.rcpt)
        end)

        it('sets SMTP server and credentials', function()
            mailer:send({
                from = 'bot@example.com',
                to = 'user@example.com',
                subject = 'Test',
                body = 'Hello',
            })
            assert.equals('smtp.example.com', captured_params.server)
            assert.equals(587, captured_params.port)
            assert.equals('bot@example.com', captured_params.user)
            assert.equals('secret', captured_params.password)
        end)

        it('send_text convenience method works', function()
            mailer:send_text('bot@example.com', 'user@example.com', 'Subject', 'Body text')
            assert.equals('<bot@example.com>', captured_params.from)
            assert.equals(1, #captured_params.rcpt)
        end)

        it('send_html convenience method works', function()
            mailer:send_html('bot@example.com', 'user@example.com', 'Subject', '<p>HTML</p>')
            assert.equals('<bot@example.com>', captured_params.from)
            assert.equals(1, #captured_params.rcpt)
        end)

        it('returns true on success', function()
            local result = mailer:send({
                from = 'bot@example.com',
                to = 'user@example.com',
                subject = 'Test',
                body = 'Hello',
            })
            assert.is_true(result)
        end)

        it('handles send failure', function()
            local smtp = require('socket.smtp')
            smtp.send = function()
                return nil, 'Connection refused'
            end

            local ok, err = mailer:send({
                from = 'bot@example.com',
                to = 'user@example.com',
                subject = 'Test',
                body = 'Hello',
            })
            assert.is_false(ok)
            assert.truthy(tostring(err):find('SMTP send failed'))
        end)
    end)
end)
