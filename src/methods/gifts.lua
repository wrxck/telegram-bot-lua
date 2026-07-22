--- gifts API methods.
-- @module telegram-bot-lua.methods.gifts
return function(api)
    local config = require('telegram-bot-lua.config')

    --- get the list of gifts received by a user.
    -- @param user_id number unique identifier of the target user
    -- @return table|false the user gifts object, or false on failure
    -- @return string|table the HTTP status or error details
    function api.get_user_gifts(user_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getUserGifts', {
            ['user_id'] = user_id
        })
        return success, res
    end

    --- get the list of gifts that can be sent by the bot.
    -- @return table|false the available gifts object, or false on failure
    -- @return string|table the HTTP status or error details
    function api.get_available_gifts()
        local success, res = api.request(config.endpoint .. api.token .. '/getAvailableGifts')
        return success, res
    end

    --- send a gift to a user.
    -- @param user_id number unique identifier of the target user
    -- @param gift_id string identifier of the gift to send
    -- @param opts table optional parameters (text, text_parse_mode, pay_for_upgrade)
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.send_gift(user_id, gift_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/sendGift', {
            ['user_id'] = user_id,
            ['gift_id'] = gift_id,
            ['text'] = opts.text,
            ['text_parse_mode'] = opts.text_parse_mode,
            ['pay_for_upgrade'] = opts.pay_for_upgrade
        })
        return success, res
    end

    --- transfer an owned unique gift to another user.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param owned_gift_id string unique identifier of the regular gift that should be transferred
    -- @param new_owner_chat_id number unique identifier of the chat which will own the gift
    -- @param opts table optional parameters
    -- @param opts.star_count number the amount of telegram stars that will be paid for the transfer
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.transfer_gift(business_connection_id, owned_gift_id, new_owner_chat_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/transferGift', {
            ['business_connection_id'] = business_connection_id,
            ['owned_gift_id'] = owned_gift_id,
            ['new_owner_chat_id'] = new_owner_chat_id,
            ['star_count'] = opts.star_count
        })
        return success, res
    end

    --- upgrade a given regular gift to a unique gift.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param owned_gift_id string unique identifier of the regular gift that should be upgraded
    -- @param opts table optional parameters
    -- @param opts.keep_original_details boolean pass true to keep the original gift text, sender and receiver
    -- @param opts.star_count number the amount of telegram stars that will be paid for the upgrade
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.upgrade_gift(business_connection_id, owned_gift_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/upgradeGift', {
            ['business_connection_id'] = business_connection_id,
            ['owned_gift_id'] = owned_gift_id,
            ['keep_original_details'] = opts.keep_original_details,
            ['star_count'] = opts.star_count
        })
        return success, res
    end

    --- convert a given regular gift to telegram stars.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param owned_gift_id string unique identifier of the regular gift that should be converted
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.convert_gift_to_stars(business_connection_id, owned_gift_id)
        local success, res = api.request(config.endpoint .. api.token .. '/convertGiftToStars', {
            ['business_connection_id'] = business_connection_id,
            ['owned_gift_id'] = owned_gift_id
        })
        return success, res
    end

    --- gift a telegram premium subscription to a given user.
    -- @param user_id number unique identifier of the target user who will receive the subscription
    -- @param month_count number number of months the subscription will be active; one of 3, 6, or 12
    -- @param star_count number number of telegram stars to pay for the subscription
    -- @param opts table optional parameters
    -- @param opts.text string text shown along with the service message; 0-128 characters
    -- @param opts.text_parse_mode string mode for parsing entities in the text
    -- @param opts.text_entities table|string a JSON-serialized list of special entities in the gift text
    -- @return table|false true on success, or false on failure
    -- @return string|table the HTTP status or error details
    function api.gift_premium_subscription(user_id, month_count, star_count, opts)
        opts = opts or {}
        local text_entities = opts.text_entities
        text_entities = api._json_enc(text_entities)
        local success, res = api.request(config.endpoint .. api.token .. '/giftPremiumSubscription', {
            ['user_id'] = user_id,
            ['month_count'] = month_count,
            ['star_count'] = star_count,
            ['text'] = opts.text,
            ['text_parse_mode'] = opts.text_parse_mode,
            ['text_entities'] = text_entities
        })
        return success, res
    end
end
