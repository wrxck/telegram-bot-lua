# Update Handlers

Override these functions on the `api` table to handle incoming updates.

## Message Handlers

| Handler | Description |
|---|---|
| `api.on_update(update)` | Every raw update object |
| `api.on_message(message)` | All new messages (called after type-specific handlers) |
| `api.on_private_message(message)` | Private (DM) messages |
| `api.on_group_message(message)` | Group messages |
| `api.on_supergroup_message(message)` | Supergroup messages |
| `api.on_edited_message(message)` | All edited messages |
| `api.on_edited_private_message(message)` | Edited private messages |
| `api.on_edited_group_message(message)` | Edited group messages |
| `api.on_edited_supergroup_message(message)` | Edited supergroup messages |
| `api.on_channel_post(channel_post)` | Channel posts |
| `api.on_edited_channel_post(edited_channel_post)` | Edited channel posts |

## Query Handlers

| Handler | Description |
|---|---|
| `api.on_callback_query(callback_query)` | Inline keyboard button presses |
| `api.on_inline_query(inline_query)` | Inline mode queries |
| `api.on_chosen_inline_result(chosen_inline_result)` | Chosen inline results |
| `api.on_shipping_query(shipping_query)` | Shipping queries (payments) |
| `api.on_pre_checkout_query(pre_checkout_query)` | Pre-checkout queries (payments) |

## Chat Member Handlers

| Handler | Description |
|---|---|
| `api.on_my_chat_member(my_chat_member)` | Bot's own membership status changed |
| `api.on_chat_member(chat_member)` | Any chat member status changed |
| `api.on_chat_join_request(chat_join_request)` | User requested to join chat |

## Reaction Handlers

| Handler | Description |
|---|---|
| `api.on_message_reaction(message_reaction)` | Message reaction changed |
| `api.on_message_reaction_count(message_reaction_count)` | Anonymous reaction count changed |

## Boost Handlers

| Handler | Description |
|---|---|
| `api.on_chat_boost(chat_boost)` | Chat boost added |
| `api.on_removed_chat_boost(removed_chat_boost)` | Chat boost removed |

## Poll Handlers

| Handler | Description |
|---|---|
| `api.on_poll(poll)` | Poll state changed |
| `api.on_poll_answer(poll_answer)` | User changed poll answer |

## Business Handlers

| Handler | Description |
|---|---|
| `api.on_business_connection(business_connection)` | Business connection update |
| `api.on_business_message(business_message)` | New business message |
| `api.on_edited_business_message(edited_business_message)` | Edited business message |
| `api.on_deleted_business_messages(deleted_business_messages)` | Deleted business messages |

## Other Handlers

| Handler | Description |
|---|---|
| `api.on_purchased_paid_media(purchased_paid_media)` | Purchased paid media |

## Handler Dispatch Order

For message updates, type-specific handlers are called first, then the general handler:

1. `api.on_update(update)` (always called first)
2. `api.on_private_message(message)` / `api.on_group_message(message)` / `api.on_supergroup_message(message)`
3. `api.on_message(message)`

## Example

```lua
local api = require('telegram-bot-lua').configure('TOKEN')

-- Log all updates
function api.on_update(update)
    print('Update ID: ' .. update.update_id)
end

-- Handle private messages differently
function api.on_private_message(message)
    api.send_message(message.chat.id, 'This is a private chat!')
end

-- Handle all messages (including private ones above)
function api.on_message(message)
    if message.text and message.text:match('^/start') then
        api.send_message(message.chat.id, 'Welcome!')
    end
end

-- Handle callback queries
function api.on_callback_query(callback_query)
    api.answer_callback_query(callback_query.id, { text = 'Received!' })
end

api.run({ timeout = 60 })
```
