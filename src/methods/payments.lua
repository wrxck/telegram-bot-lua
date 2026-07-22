--- payments API methods.
-- @module telegram-bot-lua.methods.payments
return function(api)
    local config = require('telegram-bot-lua.config')

    --- send an invoice to a chat.
    -- @param chat_id string|number unique identifier for the target chat
    -- @param title string product name
    -- @param description string product description
    -- @param payload string bot-defined invoice payload
    -- @param currency string three-letter ISO 4217 currency code
    -- @param prices string|table JSON-serialised array of LabeledPrice or a table thereof
    -- @param opts table optional parameters (provider_token, max_tip_amount, suggested_tip_amounts, reply_markup, etc.)
    -- @return table|false the sent message, or false on failure
    -- @return string|table the HTTP status or error details
    function api.send_invoice(chat_id, title, description, payload, currency, prices, opts)
        opts = opts or {}
        prices = api._json_enc(prices)
        local suggested_tip_amounts = opts.suggested_tip_amounts
        suggested_tip_amounts = api._json_enc(suggested_tip_amounts)
        local provider_data = opts.provider_data
        provider_data = api._json_enc(provider_data)
        local reply_parameters = opts.reply_parameters
        reply_parameters = api._json_enc(reply_parameters)
        local reply_markup = opts.reply_markup
        reply_markup = api._json_enc(reply_markup)
        local success, res = api.request(config.endpoint .. api.token .. '/sendInvoice', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
            ['direct_messages_topic_id'] = opts.direct_messages_topic_id,
            ['title'] = title,
            ['description'] = description,
            ['payload'] = payload,
            ['provider_token'] = opts.provider_token,
            ['currency'] = currency,
            ['prices'] = prices,
            ['max_tip_amount'] = opts.max_tip_amount,
            ['suggested_tip_amounts'] = suggested_tip_amounts,
            ['start_parameter'] = opts.start_parameter,
            ['provider_data'] = provider_data,
            ['photo_url'] = opts.photo_url,
            ['photo_size'] = opts.photo_size,
            ['photo_width'] = opts.photo_width,
            ['photo_height'] = opts.photo_height,
            ['need_name'] = opts.need_name,
            ['need_phone_number'] = opts.need_phone_number,
            ['need_email'] = opts.need_email,
            ['need_shipping_address'] = opts.need_shipping_address,
            ['send_phone_number_to_provider'] = opts.send_phone_number_to_provider,
            ['send_email_to_provider'] = opts.send_email_to_provider,
            ['is_flexible'] = opts.is_flexible,
            ['disable_notification'] = opts.disable_notification,
            ['protect_content'] = opts.protect_content,
            ['suggested_post_parameters'] = api._json_enc(opts.suggested_post_parameters),
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    --- create a link for an invoice.
    -- @param title string product name
    -- @param description string product description
    -- @param payload string bot-defined invoice payload
    -- @param currency string three-letter ISO 4217 currency code
    -- @param prices string|table JSON-serialised array of LabeledPrice or a table thereof
    -- @param opts table optional parameters (provider_token, max_tip_amount, suggested_tip_amounts, etc.)
    -- @return table|false the created invoice link as a string, or false on failure
    -- @return string|table the HTTP status or error details
    function api.create_invoice_link(title, description, payload, currency, prices, opts)
        opts = opts or {}
        prices = api._json_enc(prices)
        local suggested_tip_amounts = opts.suggested_tip_amounts
        suggested_tip_amounts = api._json_enc(suggested_tip_amounts)
        local provider_data = opts.provider_data
        provider_data = api._json_enc(provider_data)
        local success, res = api.request(config.endpoint .. api.token .. '/createInvoiceLink', {
            ['title'] = title,
            ['description'] = description,
            ['payload'] = payload,
            ['provider_token'] = opts.provider_token,
            ['currency'] = currency,
            ['prices'] = prices,
            ['max_tip_amount'] = opts.max_tip_amount,
            ['suggested_tip_amounts'] = suggested_tip_amounts,
            ['provider_data'] = provider_data,
            ['photo_url'] = opts.photo_url,
            ['photo_size'] = opts.photo_size,
            ['photo_width'] = opts.photo_width,
            ['photo_height'] = opts.photo_height,
            ['need_name'] = opts.need_name,
            ['need_phone_number'] = opts.need_phone_number,
            ['need_email'] = opts.need_email,
            ['need_shipping_address'] = opts.need_shipping_address,
            ['send_phone_number_to_provider'] = opts.send_phone_number_to_provider,
            ['send_email_to_provider'] = opts.send_email_to_provider,
            ['is_flexible'] = opts.is_flexible
        })
        return success, res
    end

    --- reply to shipping queries with available shipping options or an error.
    -- @param shipping_query_id string unique identifier for the query to be answered
    -- @param ok boolean whether delivery to the specified address is possible
    -- @param opts table optional parameters (shipping_options, error_message)
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.answer_shipping_query(shipping_query_id, ok, opts)
        opts = opts or {}
        local shipping_options = opts.shipping_options
        shipping_options = api._json_enc(shipping_options)
        local error_message = opts.error_message
        if type(ok) == 'boolean' and ok == false and not error_message then
            error_message = 'Unspecified issue occurred! Please contact the person you received this invoice from!'
        end
        local success, res = api.request(config.endpoint .. api.token .. '/answerShippingQuery', {
            ['shipping_query_id'] = shipping_query_id,
            ['ok'] = ok,
            ['shipping_options'] = shipping_options,
            ['error_message'] = error_message
        })
        return success, res
    end

    --- respond to a pre-checkout query confirming or rejecting the order.
    -- @param pre_checkout_query_id string unique identifier for the query to be answered
    -- @param ok boolean whether the bot is ready to proceed with the order
    -- @param opts table optional parameters (error_message)
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.answer_pre_checkout_query(pre_checkout_query_id, ok, opts)
        opts = opts or {}
        local error_message = opts.error_message
        if type(ok) == 'boolean' and ok == false and not error_message then
            error_message = 'Unspecified issue occurred! Please contact the person you received this invoice from!'
        end
        local success, res = api.request(config.endpoint .. api.token .. '/answerPreCheckoutQuery', {
            ['pre_checkout_query_id'] = pre_checkout_query_id,
            ['ok'] = ok,
            ['error_message'] = error_message
        })
        return success, res
    end

    --- get the bot's telegram star transactions.
    -- @param opts table optional parameters (offset, limit)
    -- @return table|false the star transactions object, or false on failure
    -- @return string|table the HTTP status or error details
    function api.get_star_transactions(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getStarTransactions', {
            ['offset'] = opts.offset,
            ['limit'] = opts.limit
        })
        return success, res
    end

    --- refund a successful payment in telegram stars.
    -- @param user_id number identifier of the user whose payment will be refunded
    -- @param telegram_payment_charge_id string telegram payment identifier
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.refund_star_payment(user_id, telegram_payment_charge_id)
        local success, res = api.request(config.endpoint .. api.token .. '/refundStarPayment', {
            ['user_id'] = user_id,
            ['telegram_payment_charge_id'] = telegram_payment_charge_id
        })
        return success, res
    end

    --- edit a user's star subscription status (cancel or re-enable).
    -- @param user_id number identifier of the user whose subscription will be edited
    -- @param telegram_payment_charge_id string telegram payment identifier for the subscription
    -- @param is_canceled boolean whether the subscription should be cancelled
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.edit_user_star_subscription(user_id, telegram_payment_charge_id, is_canceled)
        local success, res = api.request(config.endpoint .. api.token .. '/editUserStarSubscription', {
            ['user_id'] = user_id,
            ['telegram_payment_charge_id'] = telegram_payment_charge_id,
            ['is_canceled'] = is_canceled
        })
        return success, res
    end

    --- get the current telegram stars balance of the bot.
    -- @return table|false the star amount object, or false on failure
    -- @return string|table the HTTP status or error details
    function api.get_my_star_balance()
        local success, res = api.request(config.endpoint .. api.token .. '/getMyStarBalance')
        return success, res
    end
end
