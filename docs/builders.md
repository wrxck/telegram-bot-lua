# Builders and Constructors

## Inline Keyboard

Chainable builder for inline keyboards:

```lua
local kb = api.inline_keyboard()
    :row(api.row()
        :callback_data_button('Option A', 'opt_a')
        :callback_data_button('Option B', 'opt_b'))
    :row(api.row()
        :url_button('Visit Site', 'https://example.com'))

api.send_message(chat_id, 'Choose:', { reply_markup = kb })
```

### Row button methods

| Method | Description |
|---|---|
| `:callback_data_button(text, callback_data)` | Button that sends callback data |
| `:url_button(text, url)` | Button that opens a URL |
| `:switch_inline_query_button(text, query)` | Switch to inline query |
| `:switch_inline_query_current_chat_button(text, query)` | Inline query in current chat |
| `:pay_button(text, pay)` | Payment button |

### Standalone button constructors

```lua
api.url_button(text, url, encoded)
api.callback_data_button(text, callback_data, encoded)
api.switch_inline_query_button(text, query, encoded)
api.switch_inline_query_current_chat_button(text, query, encoded)
api.callback_game_button(text, callback_game, encoded)
api.pay_button(text, pay, encoded)
```

Pass `encoded = true` to get a JSON string instead of a table.

## Regular Keyboard

```lua
local kb = api.keyboard(true, true)  -- resize_keyboard, one_time_keyboard
    :row({'Button 1', 'Button 2'})
    :row({'Button 3'})

api.send_message(chat_id, 'Choose:', { reply_markup = kb })
```

## Remove Keyboard

```lua
api.send_message(chat_id, 'Keyboard removed', {
    reply_markup = api.remove_keyboard()
})
```

## Inline Results

Chainable builder for inline query results:

```lua
local result = api.inline_result()
    :type('article')
    :id('1')
    :title('Example Article')
    :description('This is a description')
    :input_message_content(api.input_text_message_content('Article text', 'HTML'))
    :thumbnail_url('https://example.com/thumb.jpg')
    :thumbnail_width(100)
    :thumbnail_height(100)
```

### Available chain methods

`:type()`, `:id()`, `:title()`, `:description()`, `:url()`, `:hide_url()`,
`:input_message_content()`, `:reply_markup()`, `:thumbnail_url()`,
`:thumbnail_width()`, `:thumbnail_height()`, `:photo_url()`, `:photo_width()`,
`:photo_height()`, `:caption()`, `:gif_url()`, `:gif_width()`, `:gif_height()`,
`:mpeg4_url()`, `:mpeg4_width()`, `:mpeg4_height()`, `:video_url()`,
`:mime_type()`, `:video_width()`, `:video_height()`, `:video_duration()`,
`:audio_url()`, `:performer()`, `:audio_duration()`, `:voice_url()`,
`:voice_duration()`, `:document_url()`, `:latitude()`, `:longitude()`,
`:live_period()`, `:address()`, `:foursquare_id()`, `:phone_number()`,
`:first_name()`, `:last_name()`, `:game_short_name()`

## Input Message Content

```lua
api.input_text_message_content(message_text, parse_mode, link_preview_options, encoded)
api.input_location_message_content(latitude, longitude, encoded)
api.input_venue_message_content(latitude, longitude, title, address, foursquare_id, encoded)
api.input_contact_message_content(phone_number, first_name, last_name, encoded)
```

## Input Media

```lua
-- Standalone constructors (return media_table, file_table)
api.input_media_photo(media, caption, parse_mode)
api.input_media_video(media, thumbnail, caption, parse_mode, width, height, duration, supports_streaming)
api.input_media_animation(media, thumbnail, caption, parse_mode, width, height, duration)
api.input_media_audio(media, thumbnail, caption, parse_mode, duration, performer, title)
api.input_media_document(media, thumbnail, caption, parse_mode)

-- Chainable builder
local media = api.input_media()
    :photo('photo_file_id', 'First photo')
    :photo('photo_file_id_2', 'Second photo')
    :video('video_file_id', 'A video', 1280, 720, 120)
```

## Prices

Chainable builder for payment prices:

```lua
local prices = api.prices()
    :labeled_price('Item', 500)
    :labeled_price('Shipping', 100)

api.send_invoice(chat_id, 'Order', 'Your order', 'payload', 'USD', prices)
```

## Shipping Options

```lua
local options = api.shipping_options()
    :shipping_option('standard', 'Standard', api.prices():labeled_price('Standard', 500))
    :shipping_option('express', 'Express', api.prices():labeled_price('Express', 1000))
```

## Type Constructors

### Chat Permissions

```lua
api.chat_permissions({
    can_send_messages = true,
    can_send_photos = true,
    can_send_videos = true,
    can_send_polls = true,
    can_change_info = false,
    can_invite_users = true,
    can_pin_messages = false,
    can_manage_topics = false
})
```

### Chat Administrator Rights

```lua
api.chat_administrator_rights({
    can_manage_chat = true,
    can_delete_messages = true,
    can_restrict_members = true,
    can_manage_direct_messages = true
})
```

### Bot Commands

```lua
api.bot_command('start', 'Start the bot')
api.bot_command('help', 'Show help')

-- Scopes
api.bot_command_scope_default()
api.bot_command_scope_all_private_chats()
api.bot_command_scope_all_group_chats()
api.bot_command_scope_all_chat_administrators()
api.bot_command_scope_chat(chat_id)
api.bot_command_scope_chat_administrators(chat_id)
api.bot_command_scope_chat_member(chat_id, user_id)
```

### Menu Buttons

```lua
api.menu_button_commands()
api.menu_button_web_app(text, web_app)
api.menu_button_default()
```

### Reaction Types

```lua
api.reaction_type_emoji('👍')
api.reaction_type_custom_emoji('custom_emoji_id')
```

### Reply Parameters

```lua
api.reply_parameters(message_id, chat_id, allow_sending_without_reply, quote, quote_parse_mode, quote_entities, quote_position)
```

### Link Preview Options

```lua
api.link_preview_options(is_disabled, url, prefer_small_media, prefer_large_media, show_above_text)
```

### Message Entity

```lua
api.message_entity(entity_type, offset, length, url, user, language, custom_emoji_id)
```

### Passport Element Errors

```lua
api.passport_element_error_data_field(error_type, field_name, data_hash, message)
api.passport_element_error_front_side(error_type, file_hash, message)
api.passport_element_error_reverse_side(error_type, file_hash, message)
api.passport_element_error_selfie(error_type, file_hash, message)
api.passport_element_error_file(error_type, file_hash, message)
api.passport_element_error_files(error_type, file_hashes, message)
api.passport_element_error_translation_file(error_type, file_hash, message)
api.passport_element_error_translation_files(error_type, file_hashes, message)
api.passport_element_error_unspecified(error_type, element_hash, message)
```
