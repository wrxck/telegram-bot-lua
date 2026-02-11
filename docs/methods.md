# API Methods

All methods follow the pattern: required args positional, optional args in an `opts` table.

Methods return two values: `result, error_info`. On success, `result` contains the API response. On failure, `result` is `false`.

## Messages

```lua
api.send_message(chat_id, text, opts)
api.send_reply(message, text, opts)
api.forward_message(chat_id, from_chat_id, message_id, opts)
api.forward_messages(chat_id, from_chat_id, message_ids, opts)
api.copy_message(chat_id, from_chat_id, message_id, opts)
api.copy_messages(chat_id, from_chat_id, message_ids, opts)
api.send_photo(chat_id, photo, opts)
api.send_audio(chat_id, audio, opts)
api.send_document(chat_id, document, opts)
api.send_video(chat_id, video, opts)
api.send_animation(chat_id, animation, opts)
api.send_voice(chat_id, voice, opts)
api.send_video_note(chat_id, video_note, opts)
api.send_media_group(chat_id, media, opts)
api.send_location(chat_id, latitude, longitude, opts)
api.send_venue(chat_id, latitude, longitude, title, address, opts)
api.send_contact(chat_id, phone_number, first_name, opts)
api.send_poll(chat_id, question, options, opts)
api.send_dice(chat_id, opts)
api.send_chat_action(chat_id, action, opts)
api.set_message_reaction(chat_id, message_id, opts)
api.send_paid_media(chat_id, star_count, media, opts)
```

### Common opts for send methods

| Key | Type | Description |
|---|---|---|
| `parse_mode` | string/boolean | `'HTML'`, `'MarkdownV2'`, `'Markdown'`, or `true` (MarkdownV2) |
| `reply_markup` | table | Keyboard markup (inline_keyboard, keyboard, remove_keyboard) |
| `reply_parameters` | table | Reply configuration (use `api.reply_parameters()`) |
| `disable_notification` | boolean | Send silently |
| `protect_content` | boolean | Prevent forwarding/saving |
| `message_thread_id` | number | Forum topic ID |
| `business_connection_id` | string | Business connection ID |
| `message_effect_id` | string | Message effect ID |

### send_message example

```lua
api.send_message(chat_id, 'Hello <b>world</b>', {
    parse_mode = 'HTML',
    disable_notification = true,
    reply_markup = api.inline_keyboard()
        :row(api.row():callback_data_button('Click', 'action'))
})
```

### send_reply

Shorthand for sending a reply to an existing message:

```lua
-- message must have .chat.id and .message_id
api.send_reply(message, 'Reply text', { parse_mode = 'HTML' })
```

## Edit Methods

```lua
api.edit_message_text(chat_id, message_id, text, opts)
api.edit_message_caption(chat_id, message_id, opts)
api.edit_message_media(chat_id, message_id, media, opts)
api.edit_message_reply_markup(chat_id, message_id, opts)
api.edit_message_live_location(chat_id, message_id, latitude, longitude, opts)
api.stop_message_live_location(chat_id, message_id, opts)
api.stop_poll(chat_id, message_id, opts)
api.delete_message(chat_id, message_id)
api.delete_messages(chat_id, message_ids)
```

## Updates

```lua
api.get_updates(opts)
api.set_webhook(url, opts)
api.delete_webhook(opts)
api.get_webhook_info()
```

## Chat Management

```lua
api.get_chat(chat_id)
api.get_chat_administrators(chat_id)
api.get_chat_member_count(chat_id)
api.get_chat_member(chat_id, user_id)
api.leave_chat(chat_id)
api.set_chat_title(chat_id, title)
api.set_chat_description(chat_id, description)
api.set_chat_photo(chat_id, photo)
api.delete_chat_photo(chat_id)
api.set_chat_permissions(chat_id, permissions, opts)
api.set_chat_sticker_set(chat_id, sticker_set_name)
api.delete_chat_sticker_set(chat_id)
api.pin_chat_message(chat_id, message_id, opts)
api.unpin_chat_message(chat_id, opts)
api.unpin_all_chat_messages(chat_id)
api.export_chat_invite_link(chat_id)
api.create_chat_invite_link(chat_id, opts)
api.edit_chat_invite_link(chat_id, invite_link, opts)
api.revoke_chat_invite_link(chat_id, invite_link)
api.approve_chat_join_request(chat_id, user_id)
api.decline_chat_join_request(chat_id, user_id)
api.get_user_chat_boosts(chat_id, user_id)
```

## Member Management

```lua
api.ban_chat_member(chat_id, user_id, opts)
api.unban_chat_member(chat_id, user_id, opts)
api.restrict_chat_member(chat_id, user_id, permissions, opts)
api.promote_chat_member(chat_id, user_id, opts)
api.set_chat_administrator_custom_title(chat_id, user_id, custom_title)
api.ban_chat_sender_chat(chat_id, sender_chat_id)
api.unban_chat_sender_chat(chat_id, sender_chat_id)
api.get_user_profile_photos(user_id, opts)
```

## Forum Topics

```lua
api.get_forum_topic_icon_stickers()
api.create_forum_topic(chat_id, name, opts)
api.edit_forum_topic(chat_id, message_thread_id, opts)
api.close_forum_topic(chat_id, message_thread_id)
api.reopen_forum_topic(chat_id, message_thread_id)
api.delete_forum_topic(chat_id, message_thread_id)
api.unpin_all_forum_topic_messages(chat_id, message_thread_id)
api.edit_general_forum_topic(chat_id, name)
api.close_general_forum_topic(chat_id)
api.reopen_general_forum_topic(chat_id)
api.hide_general_forum_topic(chat_id)
api.unhide_general_forum_topic(chat_id)
api.unpin_all_general_forum_topic_messages(chat_id)
```

## Stickers

```lua
api.send_sticker(chat_id, sticker, opts)
api.get_sticker_set(name)
api.get_custom_emoji_stickers(custom_emoji_ids)
api.upload_sticker_file(user_id, sticker, sticker_format)
api.create_new_sticker_set(user_id, name, title, stickers, opts)
api.add_sticker_to_set(user_id, name, sticker)
api.set_sticker_position_in_set(sticker, position)
api.delete_sticker_from_set(sticker)
api.replace_sticker_in_set(user_id, name, old_sticker, sticker)
api.set_sticker_emoji_list(sticker, emoji_list)
api.set_sticker_keywords(sticker, keywords)
api.set_sticker_mask_position(sticker, mask_position)
api.set_sticker_set_title(name, title)
api.set_sticker_set_thumbnail(name, user_id, opts)
api.set_custom_emoji_sticker_set_thumbnail(name, opts)
api.delete_sticker_set(name)
```

## Inline

```lua
api.answer_inline_query(inline_query_id, results, opts)
api.answer_web_app_query(web_app_query_id, result)
api.answer_callback_query(callback_query_id, opts)
api.send_inline_article(inline_query_id, title, description, message_text, parse_mode, reply_markup)
api.send_inline_article_url(inline_query_id, title, url, hide_url, input_message_content, reply_markup, id)
api.send_inline_photo(inline_query_id, photo_url, caption, reply_markup)
api.send_inline_cached_photo(inline_query_id, photo_file_id, caption, reply_markup)
```

## Payments

```lua
api.send_invoice(chat_id, title, description, payload, currency, prices, opts)
api.create_invoice_link(title, description, payload, currency, prices, opts)
api.answer_shipping_query(shipping_query_id, ok, opts)
api.answer_pre_checkout_query(pre_checkout_query_id, ok, opts)
api.get_star_transactions(opts)
api.refund_star_payment(user_id, telegram_payment_charge_id)
api.edit_user_star_subscription(user_id, telegram_payment_charge_id, is_canceled)
```

## Games

```lua
api.send_game(chat_id, game_short_name, opts)
api.set_game_score(user_id, score, opts)
api.get_game_high_scores(user_id, opts)
```

## Bot Settings

```lua
api.get_me()
api.log_out()
api.close()
api.get_file(file_id)
api.set_my_commands(commands, opts)
api.delete_my_commands(opts)
api.get_my_commands(opts)
api.set_my_name(name, opts)
api.get_my_name(opts)
api.set_my_description(description, opts)
api.get_my_description(opts)
api.set_my_short_description(short_description, opts)
api.get_my_short_description(opts)
api.set_chat_menu_button(opts)
api.get_chat_menu_button(opts)
api.set_my_default_administrator_rights(opts)
api.get_my_default_administrator_rights(opts)
api.set_my_profile_photo(opts)
api.remove_my_profile_photo(opts)
```

## Passport

```lua
api.set_passport_data_errors(user_id, errors)
```

## Gifts

```lua
api.get_user_gifts(user_id)
api.get_available_gifts()
api.send_gift(user_id, gift_id, opts)
```

## Helper Methods

```lua
api.is_user_kicked(chat_id, user_id)       -- Returns: is_kicked, status
api.is_user_group_admin(chat_id, user_id)   -- Returns: is_admin, status
api.is_user_group_creator(chat_id, user_id) -- Returns: is_creator, status
api.is_user_restricted(chat_id, user_id)    -- Returns: is_restricted, status
api.has_user_left(chat_id, user_id)         -- Returns: has_left, status
api.get_chat_member_permissions(chat_id, user_id)  -- Returns permissions table
```
