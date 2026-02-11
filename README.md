# telegram-bot-lua

A feature-filled Telegram bot API library written in Lua, created by [Matt](https://t.me/wrxck). Supports Bot API 9.4 with full coverage of all available methods.

| Contents                                                              |
|-----------------------------------------------------------------------|
| [Installation](#installation)                                         |
| [Breaking Changes in v3](#breaking-changes-in-v3)                     |
| [Quick Start](#quick-start)                                           |
| [Update Handling](#update-handling)                                    |
| [API Methods](#api-methods)                                           |
| [Building Reply Markup](#building-reply-markup)                       |
| [Building Inline Results](#building-inline-results)                   |
| [Module Structure](#module-structure)                                 |

## Installation

Requires Lua 5.3+ and LuaRocks:

```
luarocks install telegram-bot-lua
```

Then in your bot:

```lua
local api = require('telegram-bot-lua').configure('bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11')
```

## Breaking Changes in v3

v3.0 is a major rewrite. The key changes:

### 1. Module entry point changed

```lua
-- v2
local api = require('telegram-bot-lua.core').configure('TOKEN')

-- v3
local api = require('telegram-bot-lua').configure('TOKEN')
```

### 2. Options table pattern for all methods with optional parameters

All API methods now use an options table instead of positional arguments:

```lua
-- v2 (positional - fragile, hard to use)
api.send_message(chat_id, text, nil, 'HTML', nil, nil, nil, nil, nil, reply_markup)

-- v3 (opts table - clean, extensible)
api.send_message(chat_id, text, { parse_mode = 'HTML', reply_markup = markup })
```

Required parameters remain positional; optional parameters go in the `opts` table.

### 3. Updated endpoint names

- `get_chat_members_count` is now `get_chat_member_count`
- `ban_chat_member` now uses the `/banChatMember` endpoint (was `/kickChatMember`)
- `get_chat` no longer scrapes t.me for bio information

### 4. Builder constructors use opts tables

```lua
-- v2
api.chat_permissions(true, true, true, true, true, true, true, true)

-- v3
api.chat_permissions({ can_send_messages = true, can_send_photos = true })
```

### 5. `api.run()` accepts an opts table

```lua
-- v2
api.run(limit, timeout, offset, allowed_updates, use_beta_endpoint)

-- v3
api.run({ limit = 100, timeout = 60 })
```

## Quick Start

```lua
local api = require('telegram-bot-lua').configure('YOUR_TOKEN')

function api.on_message(message)
    if message.text then
        api.send_message(message, message.text, {
            reply_markup = api.inline_keyboard():row(
                api.row():callback_data_button('Click me', 'btn_click')
            )
        })
    end
end

function api.on_callback_query(callback_query)
    api.answer_callback_query(callback_query.id, { text = 'You clicked!' })
end

api.run()
```

## Update Handling

Override these functions on the `api` table to handle updates:

| Handler | Description |
|---|---|
| `api.on_update(update)` | Every update |
| `api.on_message(message)` | New messages |
| `api.on_private_message(message)` | Private messages |
| `api.on_group_message(message)` | Group messages |
| `api.on_supergroup_message(message)` | Supergroup messages |
| `api.on_edited_message(message)` | Edited messages |
| `api.on_edited_private_message(message)` | Edited private messages |
| `api.on_edited_group_message(message)` | Edited group messages |
| `api.on_edited_supergroup_message(message)` | Edited supergroup messages |
| `api.on_channel_post(channel_post)` | Channel posts |
| `api.on_edited_channel_post(edited_channel_post)` | Edited channel posts |
| `api.on_callback_query(callback_query)` | Callback queries |
| `api.on_inline_query(inline_query)` | Inline queries |
| `api.on_chosen_inline_result(chosen_inline_result)` | Chosen inline results |
| `api.on_shipping_query(shipping_query)` | Shipping queries |
| `api.on_pre_checkout_query(pre_checkout_query)` | Pre-checkout queries |
| `api.on_poll(poll)` | Poll updates |
| `api.on_poll_answer(poll_answer)` | Poll answers |
| `api.on_message_reaction(message_reaction)` | Message reactions |
| `api.on_message_reaction_count(message_reaction_count)` | Reaction counts |
| `api.on_my_chat_member(my_chat_member)` | Bot's chat member status |
| `api.on_chat_member(chat_member)` | Chat member updates |
| `api.on_chat_join_request(chat_join_request)` | Join requests |
| `api.on_chat_boost(chat_boost)` | Chat boosts |
| `api.on_removed_chat_boost(removed_chat_boost)` | Removed boosts |
| `api.on_business_connection(business_connection)` | Business connections |
| `api.on_business_message(business_message)` | Business messages |
| `api.on_edited_business_message(edited_business_message)` | Edited business messages |
| `api.on_deleted_business_messages(deleted_business_messages)` | Deleted business messages |
| `api.on_purchased_paid_media(purchased_paid_media)` | Purchased paid media |

## API Methods

All methods follow the pattern: required args positional, optional args in an `opts` table.

### Messages

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

### Updates

```lua
api.get_updates(opts)
api.set_webhook(url, opts)
api.delete_webhook(opts)
api.get_webhook_info()
```

### Chat

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

### Members

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

### Forum Topics

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

### Stickers

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

### Inline

```lua
api.answer_inline_query(inline_query_id, results, opts)
api.answer_web_app_query(web_app_query_id, result)
api.answer_callback_query(callback_query_id, opts)
api.send_inline_article(inline_query_id, title, description, message_text, parse_mode, reply_markup)
api.send_inline_article_url(inline_query_id, title, url, hide_url, input_message_content, reply_markup, id)
api.send_inline_photo(inline_query_id, photo_url, caption, reply_markup)
api.send_inline_cached_photo(inline_query_id, photo_file_id, caption, reply_markup)
```

### Payments

```lua
api.send_invoice(chat_id, title, description, payload, currency, prices, opts)
api.create_invoice_link(title, description, payload, currency, prices, opts)
api.answer_shipping_query(shipping_query_id, ok, opts)
api.answer_pre_checkout_query(pre_checkout_query_id, ok, opts)
api.get_star_transactions(opts)
api.refund_star_payment(user_id, telegram_payment_charge_id)
api.edit_user_star_subscription(user_id, telegram_payment_charge_id, is_canceled)
```

### Games

```lua
api.send_game(chat_id, game_short_name, opts)
api.set_game_score(user_id, score, opts)
api.get_game_high_scores(user_id, opts)
```

### Bot

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

### Passport

```lua
api.set_passport_data_errors(user_id, errors)
```

### Gifts

```lua
api.get_user_gifts(user_id)
api.get_available_gifts()
api.send_gift(user_id, gift_id, opts)
```

### Helpers

```lua
api.is_user_kicked(chat_id, user_id)
api.is_user_group_admin(chat_id, user_id)
api.is_user_group_creator(chat_id, user_id)
api.is_user_restricted(chat_id, user_id)
api.has_user_left(chat_id, user_id)
api.get_chat_member_permissions(chat_id, user_id)
```

## Building Reply Markup

### Inline Keyboard

```lua
api.send_message(chat_id, 'Hello!', {
    reply_markup = api.inline_keyboard()
        :row(api.row():callback_data_button('Option 1', 'opt1'):callback_data_button('Option 2', 'opt2'))
        :row(api.row():url_button('Visit site', 'https://example.com'))
})
```

### Regular Keyboard

```lua
api.send_message(chat_id, 'Choose:', {
    reply_markup = api.keyboard(true, true)
        :row({'Button 1', 'Button 2'})
        :row({'Button 3'})
})
```

### Remove Keyboard

```lua
api.send_message(chat_id, 'Done', { reply_markup = api.remove_keyboard() })
```

## Building Inline Results

```lua
local result = api.inline_result()
    :type('article')
    :id('1')
    :title('Example')
    :description('An example result')
    :input_message_content(api.input_text_message_content('Result text'))
    :thumbnail_url('https://example.com/thumb.jpg')
```

## Module Structure

```
src/
  init.lua              -- Entry point, core HTTP, module loader
  config.lua            -- API endpoint configuration
  b64url.lua            -- Base64 URL encoding/decoding
  tools.lua             -- Utility functions
  handlers.lua          -- Update routing and on_* stubs
  builders.lua          -- Keyboard, inline result, and type constructors
  helpers.lua           -- Member status check helpers
  methods/
    messages.lua        -- send_*, forward_*, copy_*, edit_*, delete_*
    updates.lua         -- get_updates, webhooks
    chat.lua            -- Chat management
    members.lua         -- Member management (ban, restrict, promote)
    forum.lua           -- Forum topic management
    stickers.lua        -- Sticker operations
    inline.lua          -- Inline queries and callback queries
    payments.lua        -- Invoices, payments, stars
    games.lua           -- Game methods
    passport.lua        -- Passport data errors
    bot.lua             -- Bot profile and settings
    gifts.lua           -- Gift methods
    checklists.lua      -- Checklist methods
    stories.lua         -- Story methods
    suggested_posts.lua -- Suggested post methods
```

## License

This project is licensed under the GPL-3.0 License - see the LICENSE file for details.

Copyright (c) 2017-2026 Matthew Hesketh
