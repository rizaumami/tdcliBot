do

  local utf8_char = '(' .. util.char.utf_8 .. '*)'

  local function shouts(chat_id, msg_id, text)
    local input = util.trim(text)
    input = input:upper()

    local output = ''
    local inc = 0
    local ilen = 0
    for match in input:gmatch(utf8_char) do
      if ilen < 20 then
        ilen = ilen + 1
        output = output .. match .. ' '
      end
    end
    ilen = 0
    output = output .. '\n'
    for match in input:sub(2):gmatch(utf8_char) do
      if ilen < 19 then
        local spacing = ''
        for _ = 1, inc do
          spacing = spacing .. '  '
        end
        inc = inc + 1
        ilen = ilen + 1
        output = output .. match .. ' ' .. spacing .. match .. '\n'
      end
    end
    output = '<pre>' .. util.trim(output) .. '</pre>'
    sendText(chat_id, msg_id, output)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)

    if util.isReply(msg) then
      td.getMessage(chat_id, msg.reply_to_message_id_, function(a, d)
        shouts(a.chat_id, a.msg_id, d.content_.text_)
      end, {chat_id = chat_id, msg_id = msg.id_})
    elseif matches[2] then
      shouts(chat_id, msg.id_, matches[2])
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Shouts something. Input may be the replied-to message.'),
    usage = {
      user = {
        'https://telegra.ph/Shout-03-10',
        --'<code>!shout</code>',
        --_msg('Shouts replied message.'),
        --'',
        --'<code>!shout [text]</code>',
        --_msg('Shouts <code>text</code>.'),
        --'',
      },
    },
    patterns = {
      _config.cmd .. '(shout)$',
      _config.cmd .. '(shout) (.*)$'
    },
    run = run
  }

end
