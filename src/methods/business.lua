--- business account API methods.
-- @module telegram-bot-lua.methods.business
return function(api)
    local config = require('telegram-bot-lua.config')

    --- get information about the connection of the bot with a business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @return table,number the response object and HTTP status
    function api.get_business_connection(business_connection_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getBusinessConnection', {
            ['business_connection_id'] = business_connection_id
        })
        return success, res
    end

    --- mark an incoming message as read on behalf of a business account.
    -- @param business_connection_id string unique identifier of the business connection on behalf of which to read the message
    -- @param chat_id number unique identifier of the chat in which the message was received
    -- @param message_id number unique identifier of the message to mark as read
    -- @return table,number the response object and HTTP status
    function api.read_business_message(business_connection_id, chat_id, message_id)
        local success, res = api.request(config.endpoint .. api.token .. '/readBusinessMessage', {
            ['business_connection_id'] = business_connection_id,
            ['chat_id'] = chat_id,
            ['message_id'] = message_id
        })
        return success, res
    end

    --- delete messages on behalf of a business account.
    -- @param business_connection_id string unique identifier of the business connection on behalf of which to delete the messages
    -- @param message_ids table|string a JSON-serialized list of 1-100 identifiers of messages to delete
    -- @return table,number the response object and HTTP status
    function api.delete_business_messages(business_connection_id, message_ids)
        message_ids = api._json_enc(message_ids)
        local success, res = api.request(config.endpoint .. api.token .. '/deleteBusinessMessages', {
            ['business_connection_id'] = business_connection_id,
            ['message_ids'] = message_ids
        })
        return success, res
    end

    --- change the first and last name of a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param first_name string the new value of the first name for the business account; 1-64 characters
    -- @param opts table optional parameters
    -- @param opts.last_name string the new value of the last name for the business account; 0-64 characters
    -- @return table,number the response object and HTTP status
    function api.set_business_account_name(business_connection_id, first_name, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setBusinessAccountName', {
            ['business_connection_id'] = business_connection_id,
            ['first_name'] = first_name,
            ['last_name'] = opts.last_name
        })
        return success, res
    end

    --- change the username of a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param opts table optional parameters
    -- @param opts.username string the new value of the username for the business account; 0-32 characters
    -- @return table,number the response object and HTTP status
    function api.set_business_account_username(business_connection_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setBusinessAccountUsername', {
            ['business_connection_id'] = business_connection_id,
            ['username'] = opts.username
        })
        return success, res
    end

    --- change the bio of a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param opts table optional parameters
    -- @param opts.bio string the new value of the bio for the business account; 0-140 characters
    -- @return table,number the response object and HTTP status
    function api.set_business_account_bio(business_connection_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/setBusinessAccountBio', {
            ['business_connection_id'] = business_connection_id,
            ['bio'] = opts.bio
        })
        return success, res
    end

    --- change the profile photo of a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param photo table|string a JSON-serialized InputProfilePhoto to set
    -- @param opts table optional parameters
    -- @param opts.is_public boolean pass true to set the public photo
    -- @return table,number the response object and HTTP status
    function api.set_business_account_profile_photo(business_connection_id, photo, opts)
        opts = opts or {}
        photo = api._json_enc(photo)
        local success, res = api.request(config.endpoint .. api.token .. '/setBusinessAccountProfilePhoto', {
            ['business_connection_id'] = business_connection_id,
            ['photo'] = photo,
            ['is_public'] = opts.is_public
        })
        return success, res
    end

    --- remove the current profile photo of a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param opts table optional parameters
    -- @param opts.is_public boolean pass true to remove the public photo
    -- @return table,number the response object and HTTP status
    function api.remove_business_account_profile_photo(business_connection_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/removeBusinessAccountProfilePhoto', {
            ['business_connection_id'] = business_connection_id,
            ['is_public'] = opts.is_public
        })
        return success, res
    end

    --- change the privacy settings pertaining to incoming gifts in a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param show_gift_button boolean pass true if a gift button must always be shown in the input field
    -- @param accepted_gift_types table|string a JSON-serialized AcceptedGiftTypes object
    -- @return table,number the response object and HTTP status
    function api.set_business_account_gift_settings(business_connection_id, show_gift_button, accepted_gift_types)
        accepted_gift_types = api._json_enc(accepted_gift_types)
        local success, res = api.request(config.endpoint .. api.token .. '/setBusinessAccountGiftSettings', {
            ['business_connection_id'] = business_connection_id,
            ['show_gift_button'] = show_gift_button,
            ['accepted_gift_types'] = accepted_gift_types
        })
        return success, res
    end

    --- get the amount of telegram stars owned by a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @return table,number the response object and HTTP status
    function api.get_business_account_star_balance(business_connection_id)
        local success, res = api.request(config.endpoint .. api.token .. '/getBusinessAccountStarBalance', {
            ['business_connection_id'] = business_connection_id
        })
        return success, res
    end

    --- transfer telegram stars from a managed business account to the bot.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param star_count number number of telegram stars to transfer; 1-10000
    -- @return table,number the response object and HTTP status
    function api.transfer_business_account_stars(business_connection_id, star_count)
        local success, res = api.request(config.endpoint .. api.token .. '/transferBusinessAccountStars', {
            ['business_connection_id'] = business_connection_id,
            ['star_count'] = star_count
        })
        return success, res
    end

    --- get the gifts received and owned by a managed business account.
    -- @param business_connection_id string unique identifier of the business connection
    -- @param opts table optional parameters
    -- @param opts.exclude_unsaved boolean pass true to exclude gifts that aren't saved to the account's profile page
    -- @param opts.exclude_saved boolean pass true to exclude gifts that are saved to the account's profile page
    -- @param opts.exclude_unlimited boolean pass true to exclude gifts that can be purchased an unlimited number of times
    -- @param opts.exclude_limited_upgradable boolean pass true to exclude limited gifts that can be upgraded to unique
    -- @param opts.exclude_limited_non_upgradable boolean pass true to exclude limited gifts that can't be upgraded to unique
    -- @param opts.exclude_unique boolean pass true to exclude unique gifts
    -- @param opts.exclude_from_blockchain boolean pass true to exclude gifts assigned from the TON blockchain
    -- @param opts.sort_by_price boolean pass true to sort results by gift price instead of send date
    -- @param opts.offset string offset of the first entry to return as received from the previous request
    -- @param opts.limit number the maximum number of gifts to be returned; 1-100
    -- @return table,number the response object and HTTP status
    function api.get_business_account_gifts(business_connection_id, opts)
        opts = opts or {}
        local success, res = api.request(config.endpoint .. api.token .. '/getBusinessAccountGifts', {
            ['business_connection_id'] = business_connection_id,
            ['exclude_unsaved'] = opts.exclude_unsaved,
            ['exclude_saved'] = opts.exclude_saved,
            ['exclude_unlimited'] = opts.exclude_unlimited,
            ['exclude_limited_upgradable'] = opts.exclude_limited_upgradable,
            ['exclude_limited_non_upgradable'] = opts.exclude_limited_non_upgradable,
            ['exclude_unique'] = opts.exclude_unique,
            ['exclude_from_blockchain'] = opts.exclude_from_blockchain,
            ['sort_by_price'] = opts.sort_by_price,
            ['offset'] = opts.offset,
            ['limit'] = opts.limit
        })
        return success, res
    end
end
