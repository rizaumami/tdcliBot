do

  local function replacePatterns(arg, data)
    local patterns = arg.text:match('s/.*')
    local m1, m2 = patterns:match('s/(.-)/(.-)/?$')

    if not m2 then return true end

    local res

    res, text = pcall(
      function()
        return arg.replied_text:gsub(m1, m2)
      end
    )
    if res == false then
      sendText(arg.chat_id, arg.msg_id, _msg('Malformed pattern!'))
    else
      text = util.trim(text:sub(1, 4000))
      text = _msg('<b>Hi, %s, did you mean:</b>\n"%s"'):format(data.first_name_, text)
      sendText(arg.chat_id, arg.msg_id, text)
    end
  end

  local function patternsByReply(arg, data)
    local text = data.content_.text_

    if not text:match(', did you mean:') then
      arg.replied_text = text
      arg.msg_id = data.id_
      td.getUser(data.sender_user_id_, replacePatterns, arg)
    end
  end

  local function run(msg, matches)
    if util.isReply(msg) then
      td.getMessage(msg.chat_id_, msg.reply_to_message_id_, patternsByReply, {
          chat_id = msg.chat_id_,
          text = msg.content_.text_
      })
    end
  end

  return {
    description = _msg('Replace all matches for the given pattern.'),
    usage = {
      user = {
        '<code>/s/from/to/</code>',
        '<code>/s/from/to</code>',
        '<code>s/from/to</code>',
        '<code>!s/from/to/</code>',
        '<code>!s/from/to</code>',
        _msg('Replace <code>from</code> with <code>to</code>')
      },
    },
    patterns = {
      _config.cmd .. '?s/.-/.-/?$'
    },
    run = run
  }

end
