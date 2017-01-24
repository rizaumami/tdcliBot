do

  local function getUdescription(chat_id, msg_id, query)
    local url = 'http://api.urbandictionary.com/v0/define?term=' .. URL.escape(query)
    local jstr, res = http.request(url)

    if res ~= 200 then
      sendText(chat_id, msg_id, _msg('Connection error'))
      return
    end

    local jdat = json.decode(jstr)

    if jdat.result_type == 'no_results' then
      sendText(chat_id, msg_id, _msg("<b>There aren't any definitions for</b> %s <b>yet</b>"):format(query))
      return
    end

    local output = jdat.list[1].definition

    if string.len(jdat.list[1].example) > 0 then
      output = output .. '\n\n<i>' .. jdat.list[1].example .. '</i>'
    end

    sendText(chat_id, msg_id, output)
  end

  function udByReply(arg, data)
    getUdescription(arg, data.id_, data.content_.text_)
  end

  local function run(msg, matches)
    local query = matches[1]

    if util.isReply(msg) then
      if query == 'urbandictionary' or query == 'ud' or query == 'urban' then
        td.getMessage(msg.chat_id_, msg.reply_to_message_id_, udByReply, msg.chat_id_)
      end
    else
      getUdescription(msg.chat_id_, msg.id_, query)
    end
  end

  return {
    description = _msg('Returns a definition from Urban Dictionary.'),
    usage = {
      user = {
        '<code>!ud [query]</code>',
        '<code>!urban [query]</code>',
        '<code>!urbandictionary [query]</code>',
        _msg('Returns a <code>[query]</code> definition from urbandictionary.com.\n<b>Example</b>') .. ': <code>!ud fam</code>',
        '',
        '<code>!ud</code>',
        '<code>!urban</code>',
        '<code>!urbandictionary</code>',
        _msg('By reply. Returns a <code>[query]</code> definition from urbandictionary.com.\nThe <code>[query]</code> is the replied message text.')
      },
    },
    patterns = {
      _config.cmd .. '(urbandictionary)$',
      _config.cmd .. '(ud)$',
      _config.cmd .. '(urban)$',
      _config.cmd .. 'urbandictionary (.+)$',
      _config.cmd .. 'ud (.+)$',
      _config.cmd .. 'urban (.+)$'
    },
    run = run
  }

end
