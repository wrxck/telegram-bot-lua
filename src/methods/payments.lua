return function(api)
    local json = require('dkjson')
    local config = require('telegram-bot-lua.config')

    function api.send_invoice(chat_id, title, description, payload, currency, prices, opts)
        opts = opts or {}
        prices = type(prices) == 'table' and json.encode(prices) or prices
        local suggested_tip_amounts = opts.suggested_tip_amounts
        suggested_tip_amounts = type(suggested_tip_amounts) == 'table' and json.encode(suggested_tip_amounts) or suggested_tip_amounts
        local provider_data = opts.provider_data
        provider_data = type(provider_data) == 'table' and json.encode(provider_data) or provider_data
        local reply_parameters = opts.reply_parameters
        reply_parameters = type(reply_parameters) == 'table' and json.encode(reply_parameters) or reply_parameters
        local reply_markup = opts.reply_markup
        reply_markup = type(reply_markup) == 'table' and json.encode(reply_markup) or reply_markup
        local success, res = api.request(config.endpoint .. api.token .. '/sendInvoice', {
            ['chat_id'] = chat_id,
            ['message_thread_id'] = opts.message_thread_id,
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
            ['reply_parameters'] = reply_parameters,
            ['reply_markup'] = reply_markup,
            ['message_effect_id'] = opts.message_effect_id,
            ['allow_paid_broadcast'] = opts.allow_paid_broadcast
        })
        return success, res
    end

    function api.create_invoice_link(title, description, payload, currency, prices, opts)
        opts = opts or {}
        prices = type(prices) == 'table' and json.encode(prices) or prices
        local suggested_tip_amounts = opts.suggested_tip_amounts
        suggested_tip_amounts = type(suggested_tip_amounts) == 'table' and json.encode(suggested_tip_amounts) or suggested_tip_amounts
        local provider_data = opts.provider_data
        provider_data = type(provider_data) == 'table' and json.encode(provider_data) or provider_data
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

    function api.answer_shipping_query(shipping_query_id, ok, opts)
        opts = opts or {}
        local shipping_options = opts.shipping_options
        shipping_options = type(shipping_options) == 'table' and json.encode(shipping_options) or shipping_options
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

    function api.get_star_transactions(opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getStarTransactions', {
            ['offset'] = opts.offset,
            ['limit'] = opts.limit
        })
        return success, res
    end

    function api.refund_star_payment(user_id, telegram_payment_charge_id)
        local success, res = api.request(config.endpoint .. api.token .. '/refundStarPayment', {
            ['user_id'] = user_id,
            ['telegram_payment_charge_id'] = telegram_payment_charge_id
        })
        return success, res
    end

    function api.edit_user_star_subscription(user_id, telegram_payment_charge_id, is_canceled)
        local success, res = api.request(config.endpoint .. api.token .. '/editUserStarSubscription', {
            ['user_id'] = user_id,
            ['telegram_payment_charge_id'] = telegram_payment_charge_id,
            ['is_canceled'] = is_canceled
        })
        return success, res
    end
end
