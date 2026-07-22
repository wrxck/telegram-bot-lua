-- Coverage tests for src/methods/{members,passport,payments,stickers,stories,suggested_posts,updates}.lua
local api = require('spec.test_helper')
local json = require('dkjson')

describe('coverage: methods part B', function()
    before_each(function()
        api._clear_requests()
    end)

    describe('members methods', function()
        it('ban_chat_member passes opts, works without opts', function()
            api.ban_chat_member(1, 2)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/banChatMember', 1, true))
            assert.equals(1, req.parameters.chat_id)
            assert.equals(2, req.parameters.user_id)
            assert.is_nil(req.parameters.until_date)
            api.ban_chat_member(1, 2, { until_date = 1800000000, revoke_messages = true })
            req = api._last_request()
            assert.equals(1800000000, req.parameters.until_date)
            assert.is_true(req.parameters.revoke_messages)
        end)

        it('unban_chat_member passes only_if_banned, works without opts', function()
            api.unban_chat_member(3, 4)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/unbanChatMember', 1, true))
            assert.equals(4, req.parameters.user_id)
            assert.is_nil(req.parameters.only_if_banned)
            api.unban_chat_member(3, 4, { only_if_banned = true })
            assert.is_true(api._last_request().parameters.only_if_banned)
        end)

        it('restrict_chat_member encodes permissions table and passes opts', function()
            api.restrict_chat_member(5, 6, { can_send_messages = false }, {
                use_independent_chat_permissions = true,
                until_date = 1800000001
            })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/restrictChatMember', 1, true))
            assert.equals(5, req.parameters.chat_id)
            assert.equals(6, req.parameters.user_id)
            assert.is_false(json.decode(req.parameters.permissions).can_send_messages)
            assert.is_true(req.parameters.use_independent_chat_permissions)
            assert.equals(1800000001, req.parameters.until_date)
        end)

        it('restrict_chat_member accepts string permissions without opts', function()
            api.restrict_chat_member(5, 6, '{"can_send_messages":true}')
            local req = api._last_request()
            assert.equals('{"can_send_messages":true}', req.parameters.permissions)
            assert.is_nil(req.parameters.until_date)
        end)

        it('promote_chat_member passes admin right flags, works without opts', function()
            api.promote_chat_member(7, 8)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/promoteChatMember', 1, true))
            assert.equals(8, req.parameters.user_id)
            assert.is_nil(req.parameters.can_manage_chat)
            api.promote_chat_member(7, 8, {
                is_anonymous = true,
                can_manage_chat = true,
                can_delete_messages = true,
                can_manage_video_chats = true,
                can_restrict_members = false,
                can_promote_members = false,
                can_change_info = true,
                can_invite_users = true,
                can_post_messages = true,
                can_edit_messages = true,
                can_pin_messages = true,
                can_post_stories = true,
                can_edit_stories = true,
                can_delete_stories = true,
                can_manage_topics = true,
                can_manage_direct_messages = true,
                can_manage_tags = true
            })
            req = api._last_request()
            assert.is_true(req.parameters.is_anonymous)
            assert.is_true(req.parameters.can_manage_chat)
            assert.is_true(req.parameters.can_delete_messages)
            assert.is_true(req.parameters.can_manage_video_chats)
            assert.is_false(req.parameters.can_restrict_members)
            assert.is_false(req.parameters.can_promote_members)
            assert.is_true(req.parameters.can_manage_topics)
            assert.is_true(req.parameters.can_manage_direct_messages)
            assert.is_true(req.parameters.can_manage_tags)
        end)

        it('set_chat_administrator_custom_title truncates title to 16 characters', function()
            api.set_chat_administrator_custom_title(9, 10, string.rep('a', 30))
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setChatAdministratorCustomTitle', 1, true))
            assert.equals(9, req.parameters.chat_id)
            assert.equals(10, req.parameters.user_id)
            assert.equals(16, #req.parameters.custom_title)
        end)

        it('ban_chat_sender_chat passes sender_chat_id', function()
            api.ban_chat_sender_chat(11, -100999)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/banChatSenderChat', 1, true))
            assert.equals(11, req.parameters.chat_id)
            assert.equals(-100999, req.parameters.sender_chat_id)
        end)

        it('unban_chat_sender_chat passes sender_chat_id', function()
            api.unban_chat_sender_chat(12, -100888)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/unbanChatSenderChat', 1, true))
            assert.equals(-100888, req.parameters.sender_chat_id)
        end)

        it('set_chat_member_tag passes tag, works without opts', function()
            api.set_chat_member_tag(13, 14)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setChatMemberTag', 1, true))
            assert.equals(14, req.parameters.user_id)
            assert.is_nil(req.parameters.tag)
            api.set_chat_member_tag(13, 14, { tag = 'vip' })
            assert.equals('vip', api._last_request().parameters.tag)
        end)

        it('get_user_profile_photos passes offset and limit, works without opts', function()
            api.get_user_profile_photos(15)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/getUserProfilePhotos', 1, true))
            assert.equals(15, req.parameters.user_id)
            assert.is_nil(req.parameters.offset)
            api.get_user_profile_photos(15, { offset = 2, limit = 10 })
            req = api._last_request()
            assert.equals(2, req.parameters.offset)
            assert.equals(10, req.parameters.limit)
        end)

        it('get_user_profile_audios passes offset and limit, works without opts', function()
            api.get_user_profile_audios(16)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/getUserProfileAudios', 1, true))
            assert.equals(16, req.parameters.user_id)
            assert.is_nil(req.parameters.limit)
            api.get_user_profile_audios(16, { offset = 1, limit = 5 })
            req = api._last_request()
            assert.equals(1, req.parameters.offset)
            assert.equals(5, req.parameters.limit)
        end)
    end)

    describe('passport methods', function()
        it('set_passport_data_errors encodes errors table', function()
            local ok, status = api.set_passport_data_errors(1, {{
                source = 'data',
                type = 'passport',
                field_name = 'document_no',
                data_hash = 'h',
                message = 'bad'
            }})
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setPassportDataErrors', 1, true))
            assert.equals(1, req.parameters.user_id)
            local errors = json.decode(req.parameters.errors)
            assert.equals('data', errors[1].source)
            assert.equals('bad', errors[1].message)
            assert.is_true(ok.ok)
            assert.equals(200, status)
        end)

        it('set_passport_data_errors passes a pre-encoded string through', function()
            api.set_passport_data_errors(1, '[{"source":"file"}]')
            assert.equals('[{"source":"file"}]', api._last_request().parameters.errors)
        end)
    end)

    describe('payments methods', function()
        it('send_invoice encodes prices and all JSON opts', function()
            api.send_invoice(1, 'Widget', 'A widget', 'payload1', 'GBP',
                {{ label = 'Widget', amount = 500 }}, {
                    message_thread_id = 2,
                    direct_messages_topic_id = 3,
                    provider_token = 'prov1',
                    max_tip_amount = 100,
                    suggested_tip_amounts = { 10, 20 },
                    start_parameter = 'start1',
                    provider_data = { foo = 'bar' },
                    photo_url = 'https://p.test/i.png',
                    photo_size = 1000,
                    photo_width = 640,
                    photo_height = 480,
                    need_name = true,
                    need_phone_number = true,
                    need_email = true,
                    need_shipping_address = true,
                    send_phone_number_to_provider = true,
                    send_email_to_provider = true,
                    is_flexible = true,
                    disable_notification = true,
                    protect_content = true,
                    suggested_post_parameters = { price = { amount = 1 } },
                    reply_parameters = { message_id = 4 },
                    reply_markup = { inline_keyboard = {} },
                    message_effect_id = 'fx1',
                    allow_paid_broadcast = true
                })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/sendInvoice', 1, true))
            assert.equals(1, req.parameters.chat_id)
            assert.equals('Widget', req.parameters.title)
            assert.equals('A widget', req.parameters.description)
            assert.equals('payload1', req.parameters.payload)
            assert.equals('GBP', req.parameters.currency)
            assert.equals(500, json.decode(req.parameters.prices)[1].amount)
            assert.same({ 10, 20 }, json.decode(req.parameters.suggested_tip_amounts))
            assert.equals('bar', json.decode(req.parameters.provider_data).foo)
            assert.equals(4, json.decode(req.parameters.reply_parameters).message_id)
            assert.is_table(json.decode(req.parameters.reply_markup).inline_keyboard)
            assert.equals(1, json.decode(req.parameters.suggested_post_parameters).price.amount)
            assert.equals('prov1', req.parameters.provider_token)
            assert.equals(100, req.parameters.max_tip_amount)
            assert.equals('start1', req.parameters.start_parameter)
            assert.is_true(req.parameters.need_name)
            assert.is_true(req.parameters.is_flexible)
            assert.equals('fx1', req.parameters.message_effect_id)
            assert.is_true(req.parameters.allow_paid_broadcast)
        end)

        it('send_invoice works without opts and accepts string prices', function()
            api.send_invoice(1, 'W', 'D', 'p', 'EUR', '[{"label":"W","amount":1}]')
            local req = api._last_request()
            assert.equals('[{"label":"W","amount":1}]', req.parameters.prices)
            assert.is_nil(req.parameters.provider_token)
            assert.is_nil(req.parameters.reply_markup)
        end)

        it('create_invoice_link encodes prices, tips and provider_data', function()
            api.create_invoice_link('Sub', 'Monthly', 'payload2', 'USD',
                {{ label = 'Sub', amount = 999 }}, {
                    provider_token = 'prov2',
                    max_tip_amount = 50,
                    suggested_tip_amounts = { 5 },
                    provider_data = { plan = 'pro' },
                    photo_url = 'https://p.test/s.png',
                    photo_size = 1,
                    photo_width = 2,
                    photo_height = 3,
                    need_name = true,
                    need_phone_number = false,
                    need_email = true,
                    need_shipping_address = false,
                    send_phone_number_to_provider = true,
                    send_email_to_provider = false,
                    is_flexible = true
                })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/createInvoiceLink', 1, true))
            assert.equals('Sub', req.parameters.title)
            assert.equals('USD', req.parameters.currency)
            assert.equals(999, json.decode(req.parameters.prices)[1].amount)
            assert.same({ 5 }, json.decode(req.parameters.suggested_tip_amounts))
            assert.equals('pro', json.decode(req.parameters.provider_data).plan)
            assert.equals('prov2', req.parameters.provider_token)
            assert.is_true(req.parameters.need_name)
            assert.is_false(req.parameters.need_phone_number)
            assert.is_true(req.parameters.is_flexible)
        end)

        it('create_invoice_link works without opts', function()
            api.create_invoice_link('T', 'D', 'p', 'EUR', '[]')
            local req = api._last_request()
            assert.equals('[]', req.parameters.prices)
            assert.is_nil(req.parameters.suggested_tip_amounts)
            assert.is_nil(req.parameters.provider_data)
        end)

        it('answer_shipping_query encodes shipping_options for ok=true', function()
            api.answer_shipping_query('sq1', true, {
                shipping_options = {{ id = 'a', title = 'Std', prices = {} }}
            })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/answerShippingQuery', 1, true))
            assert.equals('sq1', req.parameters.shipping_query_id)
            assert.is_true(req.parameters.ok)
            assert.equals('Std', json.decode(req.parameters.shipping_options)[1].title)
            assert.is_nil(req.parameters.error_message)
        end)

        it('answer_shipping_query supplies a default error_message when ok=false', function()
            api.answer_shipping_query('sq2', false)
            local req = api._last_request()
            assert.is_false(req.parameters.ok)
            assert.truthy(req.parameters.error_message:find('Unspecified issue occurred', 1, true))
        end)

        it('answer_shipping_query keeps a custom error_message when ok=false', function()
            api.answer_shipping_query('sq3', false, { error_message = 'No delivery here' })
            assert.equals('No delivery here', api._last_request().parameters.error_message)
        end)

        it('answer_pre_checkout_query passes ok=true with no error_message', function()
            api.answer_pre_checkout_query('pcq1', true)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/answerPreCheckoutQuery', 1, true))
            assert.equals('pcq1', req.parameters.pre_checkout_query_id)
            assert.is_true(req.parameters.ok)
            assert.is_nil(req.parameters.error_message)
        end)

        it('answer_pre_checkout_query supplies a default error_message when ok=false', function()
            api.answer_pre_checkout_query('pcq2', false)
            local req = api._last_request()
            assert.is_false(req.parameters.ok)
            assert.truthy(req.parameters.error_message:find('Unspecified issue occurred', 1, true))
        end)

        it('answer_pre_checkout_query keeps a custom error_message when ok=false', function()
            api.answer_pre_checkout_query('pcq3', false, { error_message = 'Out of stock' })
            assert.equals('Out of stock', api._last_request().parameters.error_message)
        end)

        it('get_star_transactions passes offset and limit, works without opts', function()
            api.get_star_transactions()
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/getStarTransactions', 1, true))
            assert.is_nil(req.parameters.offset)
            api.get_star_transactions({ offset = 5, limit = 50 })
            req = api._last_request()
            assert.equals(5, req.parameters.offset)
            assert.equals(50, req.parameters.limit)
        end)

        it('refund_star_payment passes user_id and charge id', function()
            api.refund_star_payment(2, 'charge_1')
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/refundStarPayment', 1, true))
            assert.equals(2, req.parameters.user_id)
            assert.equals('charge_1', req.parameters.telegram_payment_charge_id)
        end)

        it('edit_user_star_subscription passes is_canceled', function()
            api.edit_user_star_subscription(3, 'charge_2', true)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/editUserStarSubscription', 1, true))
            assert.equals(3, req.parameters.user_id)
            assert.equals('charge_2', req.parameters.telegram_payment_charge_id)
            assert.is_true(req.parameters.is_canceled)
        end)

        it('get_my_star_balance requests the endpoint with no parameters', function()
            local ok, status = api.get_my_star_balance()
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/getMyStarBalance', 1, true))
            assert.is_nil(req.parameters)
            assert.is_true(ok.ok)
            assert.equals(200, status)
        end)
    end)

    describe('stickers methods', function()
        it('send_sticker sends sticker as file payload and encodes markup opts', function()
            api.send_sticker(1, '/tmp/s.webp', {
                message_thread_id = 2,
                direct_messages_topic_id = 3,
                emoji = ':)',
                disable_notification = true,
                protect_content = true,
                suggested_post_parameters = { price = { amount = 7 } },
                reply_parameters = { message_id = 4 },
                reply_markup = { inline_keyboard = {} },
                business_connection_id = 'biz1',
                message_effect_id = 'fx',
                allow_paid_broadcast = true
            })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/sendSticker', 1, true))
            assert.equals(1, req.parameters.chat_id)
            assert.equals('/tmp/s.webp', req.file.sticker)
            assert.equals(2, req.parameters.message_thread_id)
            assert.equals(':)', req.parameters.emoji)
            assert.is_true(req.parameters.disable_notification)
            assert.equals(7, json.decode(req.parameters.suggested_post_parameters).price.amount)
            assert.equals(4, json.decode(req.parameters.reply_parameters).message_id)
            assert.is_table(json.decode(req.parameters.reply_markup).inline_keyboard)
            assert.equals('biz1', req.parameters.business_connection_id)
        end)

        it('send_sticker works without opts', function()
            api.send_sticker(1, 'file_id_1')
            local req = api._last_request()
            assert.equals('file_id_1', req.file.sticker)
            assert.is_nil(req.parameters.reply_markup)
            assert.is_nil(req.parameters.emoji)
        end)

        it('get_sticker_set passes name', function()
            api.get_sticker_set('pack1')
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/getStickerSet', 1, true))
            assert.equals('pack1', req.parameters.name)
        end)

        it('get_custom_emoji_stickers encodes the id list', function()
            api.get_custom_emoji_stickers({ 'e1', 'e2' })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/getCustomEmojiStickers', 1, true))
            assert.same({ 'e1', 'e2' }, json.decode(req.parameters.custom_emoji_ids))
        end)

        it('upload_sticker_file sends sticker as file payload with format', function()
            api.upload_sticker_file(2, '/tmp/up.png', 'static')
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/uploadStickerFile', 1, true))
            assert.equals(2, req.parameters.user_id)
            assert.equals('static', req.parameters.sticker_format)
            assert.equals('/tmp/up.png', req.file.sticker)
        end)

        it('create_new_sticker_set encodes stickers and passes opts', function()
            api.create_new_sticker_set(3, 'pack_by_bot', 'My Pack',
                {{ sticker = 'f1', format = 'static', emoji_list = { ':)' } }}, {
                    sticker_type = 'regular',
                    needs_repainting = true
                })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/createNewStickerSet', 1, true))
            assert.equals(3, req.parameters.user_id)
            assert.equals('pack_by_bot', req.parameters.name)
            assert.equals('My Pack', req.parameters.title)
            assert.equals('f1', json.decode(req.parameters.stickers)[1].sticker)
            assert.equals('regular', req.parameters.sticker_type)
            assert.is_true(req.parameters.needs_repainting)
        end)

        it('create_new_sticker_set works without opts', function()
            api.create_new_sticker_set(3, 'pack2', 'T', '[]')
            local req = api._last_request()
            assert.equals('[]', req.parameters.stickers)
            assert.is_nil(req.parameters.sticker_type)
        end)

        it('add_sticker_to_set encodes the sticker table', function()
            api.add_sticker_to_set(4, 'pack3', { sticker = 'f2', format = 'video' })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/addStickerToSet', 1, true))
            assert.equals(4, req.parameters.user_id)
            assert.equals('pack3', req.parameters.name)
            assert.equals('f2', json.decode(req.parameters.sticker).sticker)
        end)

        it('set_sticker_position_in_set passes sticker and position', function()
            api.set_sticker_position_in_set('f3', 0)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setStickerPositionInSet', 1, true))
            assert.equals('f3', req.parameters.sticker)
            assert.equals(0, req.parameters.position)
        end)

        it('delete_sticker_from_set passes sticker', function()
            api.delete_sticker_from_set('f4')
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/deleteStickerFromSet', 1, true))
            assert.equals('f4', req.parameters.sticker)
        end)

        it('replace_sticker_in_set encodes new sticker and passes old_sticker', function()
            api.replace_sticker_in_set(5, 'pack4', 'old_f', { sticker = 'new_f' })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/replaceStickerInSet', 1, true))
            assert.equals(5, req.parameters.user_id)
            assert.equals('pack4', req.parameters.name)
            assert.equals('old_f', req.parameters.old_sticker)
            assert.equals('new_f', json.decode(req.parameters.sticker).sticker)
        end)

        it('set_sticker_emoji_list encodes the emoji list', function()
            api.set_sticker_emoji_list('f5', { ':D', ':P' })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setStickerEmojiList', 1, true))
            assert.equals('f5', req.parameters.sticker)
            assert.same({ ':D', ':P' }, json.decode(req.parameters.emoji_list))
        end)

        it('set_sticker_keywords encodes the keywords list', function()
            api.set_sticker_keywords('f6', { 'cat', 'meow' })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setStickerKeywords', 1, true))
            assert.same({ 'cat', 'meow' }, json.decode(req.parameters.keywords))
        end)

        it('set_sticker_mask_position encodes the mask position table', function()
            api.set_sticker_mask_position('f7', { point = 'eyes', x_shift = 0.5 })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setStickerMaskPosition', 1, true))
            assert.equals('eyes', json.decode(req.parameters.mask_position).point)
        end)

        it('set_sticker_set_title truncates title to 64 characters', function()
            api.set_sticker_set_title('pack5', string.rep('t', 100))
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setStickerSetTitle', 1, true))
            assert.equals('pack5', req.parameters.name)
            assert.equals(64, #req.parameters.title)
        end)

        it('set_sticker_set_thumbnail sends thumbnail as file payload', function()
            api.set_sticker_set_thumbnail('pack6', 6, {
                thumbnail = '/tmp/thumb.png',
                format = 'static'
            })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setStickerSetThumbnail', 1, true))
            assert.equals('pack6', req.parameters.name)
            assert.equals(6, req.parameters.user_id)
            assert.equals('static', req.parameters.format)
            assert.equals('/tmp/thumb.png', req.file.thumbnail)
        end)

        it('set_sticker_set_thumbnail works without opts', function()
            api.set_sticker_set_thumbnail('pack6', 6)
            local req = api._last_request()
            assert.is_nil(req.parameters.format)
            assert.is_nil(req.file.thumbnail)
        end)

        it('set_custom_emoji_sticker_set_thumbnail passes custom_emoji_id, works without opts', function()
            api.set_custom_emoji_sticker_set_thumbnail('pack7')
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setCustomEmojiStickerSetThumbnail', 1, true))
            assert.equals('pack7', req.parameters.name)
            assert.is_nil(req.parameters.custom_emoji_id)
            api.set_custom_emoji_sticker_set_thumbnail('pack7', { custom_emoji_id = 'ce1' })
            assert.equals('ce1', api._last_request().parameters.custom_emoji_id)
        end)

        it('delete_sticker_set passes name', function()
            api.delete_sticker_set('pack8')
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/deleteStickerSet', 1, true))
            assert.equals('pack8', req.parameters.name)
        end)
    end)

    describe('stories methods', function()
        it('repost_story passes chat_id and story_id', function()
            local ok, status = api.repost_story(1, 99)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/repostStory', 1, true))
            assert.equals(1, req.parameters.chat_id)
            assert.equals(99, req.parameters.story_id)
            assert.is_true(ok.ok)
            assert.equals(200, status)
        end)

        it('post_story encodes content, caption_entities and areas', function()
            api.post_story('biz2', { photo = 'p1' }, 86400, {
                caption = 'Story caption',
                parse_mode = 'HTML',
                caption_entities = {{ type = 'bold', offset = 0, length = 5 }},
                areas = {{ position = { x = 1 } }},
                post_to_chat_page = true,
                protect_content = true
            })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/postStory', 1, true))
            assert.equals('biz2', req.parameters.business_connection_id)
            assert.equals('p1', json.decode(req.parameters.content).photo)
            assert.equals(86400, req.parameters.active_period)
            assert.equals('Story caption', req.parameters.caption)
            assert.equals('HTML', req.parameters.parse_mode)
            assert.equals('bold', json.decode(req.parameters.caption_entities)[1].type)
            assert.equals(1, json.decode(req.parameters.areas)[1].position.x)
            assert.is_true(req.parameters.post_to_chat_page)
            assert.is_true(req.parameters.protect_content)
        end)

        it('post_story works without opts', function()
            api.post_story('biz2', '{"photo":"p2"}', 3600)
            local req = api._last_request()
            assert.equals('{"photo":"p2"}', req.parameters.content)
            assert.is_nil(req.parameters.caption_entities)
            assert.is_nil(req.parameters.areas)
        end)

        it('edit_story encodes content, caption_entities and areas', function()
            api.edit_story('biz3', 100, { video = 'v1' }, {
                caption = 'edited',
                parse_mode = 'HTML',
                caption_entities = {{ type = 'italic', offset = 0, length = 6 }},
                areas = {{ position = { y = 2 } }}
            })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/editStory', 1, true))
            assert.equals('biz3', req.parameters.business_connection_id)
            assert.equals(100, req.parameters.story_id)
            assert.equals('v1', json.decode(req.parameters.content).video)
            assert.equals('edited', req.parameters.caption)
            assert.equals('italic', json.decode(req.parameters.caption_entities)[1].type)
            assert.equals(2, json.decode(req.parameters.areas)[1].position.y)
        end)

        it('edit_story works without opts', function()
            api.edit_story('biz3', 101, '{"video":"v2"}')
            local req = api._last_request()
            assert.equals('{"video":"v2"}', req.parameters.content)
            assert.is_nil(req.parameters.caption)
        end)

        it('delete_story passes connection and story ids', function()
            api.delete_story('biz4', 102)
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/deleteStory', 1, true))
            assert.equals('biz4', req.parameters.business_connection_id)
            assert.equals(102, req.parameters.story_id)
        end)
    end)

    describe('suggested_posts methods', function()
        it('approve_suggested_post passes suggested_post_id', function()
            local ok, status = api.approve_suggested_post('sp1')
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/approveSuggestedPost', 1, true))
            assert.equals('sp1', req.parameters.suggested_post_id)
            assert.is_true(ok.ok)
            assert.equals(200, status)
        end)

        it('decline_suggested_post passes reason, works without opts', function()
            api.decline_suggested_post('sp2')
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/declineSuggestedPost', 1, true))
            assert.equals('sp2', req.parameters.suggested_post_id)
            assert.is_nil(req.parameters.reason)
            api.decline_suggested_post('sp2', { reason = 'off topic' })
            assert.equals('off topic', api._last_request().parameters.reason)
        end)
    end)

    describe('updates methods', function()
        it('get_updates encodes allowed_updates and passes polling opts', function()
            api.get_updates({
                timeout = 30,
                offset = 100,
                limit = 50,
                allowed_updates = { 'message', 'callback_query' }
            })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/getUpdates', 1, true))
            assert.equals(30, req.parameters.timeout)
            assert.equals(100, req.parameters.offset)
            assert.equals(50, req.parameters.limit)
            assert.same({ 'message', 'callback_query' }, json.decode(req.parameters.allowed_updates))
        end)

        it('get_updates works without opts and uses the standard endpoint', function()
            api.get_updates()
            local req = api._last_request()
            assert.truthy(req.endpoint:find('https://api.telegram.org/bot', 1, true))
            assert.is_nil(req.endpoint:find('/beta/', 1, true))
            assert.is_nil(req.parameters.allowed_updates)
        end)

        it('get_updates inserts beta/ before the bot path segment when requested', function()
            api.get_updates({ use_beta_endpoint = true })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('https://api.telegram.org/beta/bot', 1, true))
            assert.truthy(req.endpoint:find('/getUpdates', 1, true))
        end)

        it('set_webhook passes url, opts and certificate file', function()
            api.set_webhook('https://hook.test/tg', {
                ip_address = '1.2.3.4',
                max_connections = 40,
                allowed_updates = { 'message' },
                drop_pending_updates = true,
                secret_token = 's3cret',
                certificate = '/tmp/cert.pem'
            })
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/setWebhook', 1, true))
            assert.equals('https://hook.test/tg', req.parameters.url)
            assert.equals('1.2.3.4', req.parameters.ip_address)
            assert.equals(40, req.parameters.max_connections)
            assert.same({ 'message' }, json.decode(req.parameters.allowed_updates))
            assert.is_true(req.parameters.drop_pending_updates)
            assert.equals('s3cret', req.parameters.secret_token)
            assert.equals('/tmp/cert.pem', req.file.certificate)
        end)

        it('set_webhook works without opts', function()
            api.set_webhook('https://hook.test/tg')
            local req = api._last_request()
            assert.equals('https://hook.test/tg', req.parameters.url)
            assert.is_nil(req.parameters.allowed_updates)
            assert.is_nil(req.file.certificate)
        end)

        it('delete_webhook passes drop_pending_updates, works without opts', function()
            api.delete_webhook()
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/deleteWebhook', 1, true))
            assert.is_nil(req.parameters.drop_pending_updates)
            api.delete_webhook({ drop_pending_updates = true })
            assert.is_true(api._last_request().parameters.drop_pending_updates)
        end)

        it('get_webhook_info requests the endpoint with no parameters', function()
            local ok, status = api.get_webhook_info()
            local req = api._last_request()
            assert.truthy(req.endpoint:find('/getWebhookInfo', 1, true))
            assert.is_nil(req.parameters)
            assert.is_true(ok.ok)
            assert.equals(200, status)
        end)
    end)
end)
