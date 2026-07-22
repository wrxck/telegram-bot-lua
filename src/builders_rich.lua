--- rich message builders (Bot API 10.1).
-- helpers for InputRichMessage payloads (sent) and the RichText / RichBlock
-- structures received in message.rich_message. each returns a plain table.
-- @module telegram-bot-lua.builders_rich
return function(api)

    -- input types (sent) ---------------------------------------------------

    --- InputRichMessage; supply exactly one of opts.html or opts.markdown.
    function api.input_rich_message(opts)
        opts = opts or {}
        -- all fields are optional; the __jsontype hint keeps an empty result
        -- encoding as a JSON object rather than [].
        return setmetatable({
            ['html'] = opts.html,
            ['markdown'] = opts.markdown,
            ['is_rtl'] = opts.is_rtl,
            ['skip_entity_detection'] = opts.skip_entity_detection
        }, { ['__jsontype'] = 'object' })
    end

    --- wrap an InputRichMessage for inline/guest/web app query results.
    function api.input_rich_message_content(rich_message)
        return { ['rich_message'] = rich_message }
    end

    --- a link object.
    function api.link(url)
        return { ['url'] = url }
    end

    --- a received rich message from an array of blocks.
    function api.rich_message(blocks, is_rtl)
        return { ['blocks'] = blocks, ['is_rtl'] = is_rtl }
    end

    -- rich text (received) -------------------------------------------------
    -- the text field of a rich text is itself a rich text: a plain string, an
    -- array of rich text, or any rich text object.

    local function simple_text(rich_type)
        return function(text)
            return { ['type'] = rich_type, ['text'] = text }
        end
    end

    -- uniform { type, text } variants
    api.rich_text_bold = simple_text('bold')
    api.rich_text_italic = simple_text('italic')
    api.rich_text_underline = simple_text('underline')
    api.rich_text_strikethrough = simple_text('strikethrough')
    api.rich_text_spoiler = simple_text('spoiler')
    api.rich_text_subscript = simple_text('subscript')
    api.rich_text_superscript = simple_text('superscript')
    api.rich_text_marked = simple_text('marked')
    api.rich_text_code = simple_text('code')

    function api.rich_text_date_time(text, unix_time, date_time_format)
        return {
            ['type'] = 'date_time',
            ['text'] = text,
            ['unix_time'] = unix_time,
            ['date_time_format'] = date_time_format
        }
    end

    function api.rich_text_text_mention(text, user)
        return { ['type'] = 'text_mention', ['text'] = text, ['user'] = user }
    end

    -- no text field
    function api.rich_text_custom_emoji(custom_emoji_id, alternative_text)
        return {
            ['type'] = 'custom_emoji',
            ['custom_emoji_id'] = custom_emoji_id,
            ['alternative_text'] = alternative_text
        }
    end

    -- no text field
    function api.rich_text_mathematical_expression(expression)
        return { ['type'] = 'mathematical_expression', ['expression'] = expression }
    end

    function api.rich_text_url(text, url)
        return { ['type'] = 'url', ['text'] = text, ['url'] = url }
    end

    function api.rich_text_email_address(text, email_address)
        return { ['type'] = 'email_address', ['text'] = text, ['email_address'] = email_address }
    end

    function api.rich_text_phone_number(text, phone_number)
        return { ['type'] = 'phone_number', ['text'] = text, ['phone_number'] = phone_number }
    end

    function api.rich_text_bank_card_number(text, bank_card_number)
        return { ['type'] = 'bank_card_number', ['text'] = text, ['bank_card_number'] = bank_card_number }
    end

    function api.rich_text_mention(text, username)
        return { ['type'] = 'mention', ['text'] = text, ['username'] = username }
    end

    function api.rich_text_hashtag(text, hashtag)
        return { ['type'] = 'hashtag', ['text'] = text, ['hashtag'] = hashtag }
    end

    function api.rich_text_cashtag(text, cashtag)
        return { ['type'] = 'cashtag', ['text'] = text, ['cashtag'] = cashtag }
    end

    function api.rich_text_bot_command(text, bot_command)
        return { ['type'] = 'bot_command', ['text'] = text, ['bot_command'] = bot_command }
    end

    -- no text field
    function api.rich_text_anchor(name)
        return { ['type'] = 'anchor', ['name'] = name }
    end

    function api.rich_text_anchor_link(text, anchor_name)
        return { ['type'] = 'anchor_link', ['text'] = text, ['anchor_name'] = anchor_name }
    end

    function api.rich_text_reference(text, name)
        return { ['type'] = 'reference', ['text'] = text, ['name'] = name }
    end

    function api.rich_text_reference_link(text, reference_name)
        return { ['type'] = 'reference_link', ['text'] = text, ['reference_name'] = reference_name }
    end

    -- rich block helpers (no type discriminator) ---------------------------

    function api.rich_block_caption(text, credit)
        return { ['text'] = text, ['credit'] = credit }
    end

    --- a table cell; opts: is_header, colspan, rowspan, align, valign.
    function api.rich_block_table_cell(text, opts)
        opts = opts or {}
        return {
            ['text'] = text,
            ['is_header'] = opts.is_header,
            ['colspan'] = opts.colspan,
            ['rowspan'] = opts.rowspan,
            ['align'] = opts.align,
            ['valign'] = opts.valign
        }
    end

    --- a list item; opts: has_checkbox, is_checked, value, type.
    function api.rich_block_list_item(label, blocks, opts)
        opts = opts or {}
        return {
            ['label'] = label,
            ['blocks'] = blocks,
            ['has_checkbox'] = opts.has_checkbox,
            ['is_checked'] = opts.is_checked,
            ['value'] = opts.value,
            ['type'] = opts.type
        }
    end

    -- rich blocks (received) -----------------------------------------------

    function api.rich_block_paragraph(text)
        return { ['type'] = 'paragraph', ['text'] = text }
    end

    --- section heading; size 1-6, 1 is largest.
    function api.rich_block_heading(text, size)
        return { ['type'] = 'heading', ['text'] = text, ['size'] = size }
    end

    function api.rich_block_preformatted(text, language)
        return { ['type'] = 'pre', ['text'] = text, ['language'] = language }
    end

    function api.rich_block_footer(text)
        return { ['type'] = 'footer', ['text'] = text }
    end

    function api.rich_block_divider()
        return { ['type'] = 'divider' }
    end

    function api.rich_block_mathematical_expression(expression)
        return { ['type'] = 'mathematical_expression', ['expression'] = expression }
    end

    function api.rich_block_anchor(name)
        return { ['type'] = 'anchor', ['name'] = name }
    end

    function api.rich_block_list(items)
        return { ['type'] = 'list', ['items'] = items }
    end

    function api.rich_block_blockquote(blocks, credit)
        return { ['type'] = 'blockquote', ['blocks'] = blocks, ['credit'] = credit }
    end

    function api.rich_block_pullquote(text, credit)
        return { ['type'] = 'pullquote', ['text'] = text, ['credit'] = credit }
    end

    function api.rich_block_collage(blocks, caption)
        return { ['type'] = 'collage', ['blocks'] = blocks, ['caption'] = caption }
    end

    function api.rich_block_slideshow(blocks, caption)
        return { ['type'] = 'slideshow', ['blocks'] = blocks, ['caption'] = caption }
    end

    --- a table; cells is an array of arrays of cells; opts: is_bordered, is_striped, caption.
    function api.rich_block_table(cells, opts)
        opts = opts or {}
        return {
            ['type'] = 'table',
            ['cells'] = cells,
            ['is_bordered'] = opts.is_bordered,
            ['is_striped'] = opts.is_striped,
            ['caption'] = opts.caption
        }
    end

    function api.rich_block_details(summary, blocks, is_open)
        return {
            ['type'] = 'details',
            ['summary'] = summary,
            ['blocks'] = blocks,
            ['is_open'] = is_open
        }
    end

    --- a map block; opts: zoom, width, height, caption.
    function api.rich_block_map(location, opts)
        opts = opts or {}
        return {
            ['type'] = 'map',
            ['location'] = location,
            ['zoom'] = opts.zoom,
            ['width'] = opts.width,
            ['height'] = opts.height,
            ['caption'] = opts.caption
        }
    end

    --- an animation block; opts: has_spoiler, caption.
    function api.rich_block_animation(animation, opts)
        opts = opts or {}
        return {
            ['type'] = 'animation',
            ['animation'] = animation,
            ['has_spoiler'] = opts.has_spoiler,
            ['caption'] = opts.caption
        }
    end

    function api.rich_block_audio(audio, caption)
        return { ['type'] = 'audio', ['audio'] = audio, ['caption'] = caption }
    end

    --- a photo block; photo is an array of photo sizes; opts: has_spoiler, caption.
    function api.rich_block_photo(photo, opts)
        opts = opts or {}
        return {
            ['type'] = 'photo',
            ['photo'] = photo,
            ['has_spoiler'] = opts.has_spoiler,
            ['caption'] = opts.caption
        }
    end

    --- a video block; opts: has_spoiler, caption.
    function api.rich_block_video(video, opts)
        opts = opts or {}
        return {
            ['type'] = 'video',
            ['video'] = video,
            ['has_spoiler'] = opts.has_spoiler,
            ['caption'] = opts.caption
        }
    end

    function api.rich_block_voice_note(voice_note, caption)
        return { ['type'] = 'voice_note', ['voice_note'] = voice_note, ['caption'] = caption }
    end

    --- a thinking placeholder; only valid in send_rich_message_draft.
    function api.rich_block_thinking(text)
        return { ['type'] = 'thinking', ['text'] = text }
    end
end
