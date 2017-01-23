do

  local function msgDump(chat_id, msg_id, value, file)
    local dump = serpent.block(value, {comment=false})
    if file then
      local textfile = '/tmp/msgdump_' .. os.date('%y%m%d-%H%M%S', value.date_) .. '.json'
      local info =  _msg('From: %s\nID: %s\nDate: %s'):format(value.chat_id_,
                                                              value.id_,
                                                              os.date('%c', value.date_)
      )

      saveConfig(value, textfile, 'noname')
      td.sendDocument(_config.bot.id, 0, 0, 1, nil, textfile, info)
      os.remove(textfile)
    else
      if #dump > 4000 then
        local text = _msg('Message is more than 4000 characters.\n'
                .. 'Use <code>%sdumptext</code> instead.'):format(_config.cmd)
      else
        sendText(chat_id, msg_id, '<code>' .. util.escapeHtml(dump) .. '</code>')
      end
    end
  end

  local function visudo(arg, data)
    local cmd = arg.cmd
    local chat_id = arg.chat_id
    local user_id = data.id_
    local name = data.first_name_
    local msg_id = arg.msg_id

    if data.username_ then
      name = '@' .. data.username_
    end
    if cmd == 'sudo' then
      if _config.sudoers[user_id] then
        local text = _msg('%s is already a sudoer.'):format(name)
        sendText(chat_id, msg_id, text)
      else
        _config.sudoers[user_id] = name
        saveConfig()
        local text = _msg('%s is now a sudoer.'):format(name)
        sendText(chat_id, msg_id, text)
      end
    elseif cmd == 'desudo' then
      if not _config.sudoers[user_id] then
        local text = _msg('%s is not a sudoer.'):format(name)
        sendText(chat_id, msg_id, text)
      elseif user_id == _config.bot.id then
        sendText(chat_id, msg_id, _msg("You can't demote yourself."))
      else
        _config.sudoers[user_id] = nil
        saveConfig()
        local text = _msg('%s is no longer a sudoer.'):format(name)
        sendText(chat_id, msg_id, text)
      end
    end
  end

  local function sudoByReply(arg, data)
    if arg.cmd == 'dump' then
      msgDump(arg.chat_id, data.id_, data)
    elseif arg.cmd == 'dumptext' then
      msgDump(arg.chat_id, data.id_, data, true)
    else
      td.getUser(data.sender_user_id_, visudo, arg)
    end
  end

  local function sudoByUsername(arg, data)
    td.getUser(data.id_, visudo, arg)
  end

  function run(msg, matches)
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_

    -- add a user as a sudo user
    if matches[1] == 'sudo' or matches[1] == 'desudo' then
      local extra = {cmd = matches[1], chat_id = msg.chat_id_, msg_id = msg.id_}

      if (msg.reply_to_message_id_ ~= 0) then
        td.getMessage(chat_id, msg.reply_to_message_id_, sudoByReply, extra)
      end
      if matches[2] then
        if matches[2]:match('^@%g+$') then
          td.searchPublicChat(matches[2], sudoByUsername, extra)
        elseif matches[2]:match('^%d+$') then
          td.getUser(matches[2], visudo, extra)
        end
      end
    end

    -- list sudoers
    if matches[1] == 'sudolist' then
      local sudoers = _msg('<b>List of sudoers</b>:\n')
      for k,v in pairs(_config.sudoers) do
        if v:match('^%d+$') then
          v = '<code>' .. v .. '</code>'
        end
        sudoers = sudoers .. '• ' .. v .. '\n'
      end
      sendText(chat_id, msg.id_, sudoers)
    end

    if matches[1] == 'bin' or matches[1] == 'run' then
      if not matches[2] then
        sendText(chat_id, msg.id_, _msg('Please specify a command to run.'))
        return
      end

      local input = matches[2]:gsub('—', '--')
      local output = util.shellCommand(input)

      if #output == 0 then
        output = 'Done!'
      else
        output =  '<code>' .. output .. '</code>'
      end
      sendText(chat_id, msg.id_, output)
    end

    if matches[1] == 'settoken' then
      local token = matches[2]
      local response = {}
      local getme  = https.request{
        url = 'https://api.telegram.org/bot' .. token .. '/getMe',
        method = "POST",
        sink = ltn12.sink.table(response),
      }
      local body = table.concat(response or {"no response"})
      local jbody = json.decode(body)

      if jbody.ok then
        local bot = jbody.result
        _config.api.token = token
        _config.api.id = bot.id
        _config.api.first_name = bot.first_name
        _config.api.username = bot.username
        saveConfig()

        sendText(chat_id, msg_id, _msg('<b>API bots token has been saved</b>'))
      else
        sendText(chat_id, msg_id, _msg('<b>Error</b>: ') .. jbody.error_code .. ', ' .. jbody.description)
      end
    end

    if matches[1] == 'setlang' then
      if not matches[2] then return end

      local lang = matches[2]:lower()

      if lang:match('%a%a') then
        _config.language = lang
        saveConfig()
        local text = _msg('Bot language is set to %s'):format(matches[2])
        sendText(chat_id, msg.id_, text)
      else
        sendText(chat_id, msg.id_, _msg('Language must be in form of two letter ISO 639-1 language code.'))
      end
    end

    if matches[1] == 'version' then
      local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
      local version = assert(f:read('*a'))
      f:close()
      local output = _msg('<b>tdcliBot</b> <code>%s</code>'):format(version)
      sendText(chat_id, msg.id_, output)
    end

    if matches[1] == 'dump' or matches[1] == 'dumptext' then
      if msg.reply_to_message_id_ ~= 0 then
        td.getMessage(chat_id, msg.reply_to_message_id_, sudoByReply, {cmd = matches[1], chat_id = chat_id})
      else
        msgDump(chat_id, msg.id_, msg, true)
      end
    end

    if matches[1] == 'getconfig' then
      td.sendDocument(_config.bot.id, 0, 0, 1, nil, config_file, os.date('%c', msg.date_))
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Various bot control commands.'),
    usage = {
      sudo = {
        '<code>!bin [command]</code>',
        '<code>!run [command]</code>',
        _msg('Run a system shell <code>command</code>'),
        '',
        '<code>!settoken [token]</code>',
        _msg('Set token or bot API key.'),
        '',
        '<code>!setlang [language]</code>',
        'Set bots language.',
        _msg('Language ID is in a form of ISO 639-1 language code.'),
        '',
        '<code>!dump</code>',
        _msg('Returns the raw json of a message.'),
        '',
        '<code>!dumptext</code>',
        _msg('Returns the raw json of a message, then send it as a file to bot private.'),
        '',
        '<code>!sudo</code>',
        _msg('Promote replied user as a sudoer.'),
        '',
        '<code>!sudo [username]</code>',
        _msg('Promote <code>username</code> as a sudoer.'),
        '',
        '<code>!sudo [user_id]</code>',
        _msg('Promote <code>user_id</code> as a sudoer.'),
        '',
        '<code>!sudolist</code>',
        _msg('Returns a list of sudo users.'),
        '',
        '<code>!desudo</code>',
        _msg('Demote replied user from sudoer.'),
        '',
        '<code>!desudo [username]</code>',
        _msg('Demote <code>username</code> from sudoer.'),
        '',
        '<code>!desudo [user_id]</code>',
        _msg('Demote <code>user_id</code> from sudoer.'),
        '',
        '<code>!version</code>',
        _msg('Shows bot version.'),
        '',
        '<code>!getconfig</code>',
        _msg('Download bots config file.'),
        '',
      },
    },
    patterns = {
      _config.cmd .. '(bin) (.*)$',
      _config.cmd .. '(run) (.*)$',
      _config.cmd .. '(setlang) (%a%a)$',
      _config.cmd .. '(dump)$',
      _config.cmd .. '(dumptext)$',
      _config.cmd .. '(getconfig)$',
      _config.cmd .. '(settoken) (.*)$',
      _config.cmd .. '(version)$',
      _config.cmd .. '(sudo)$',
      _config.cmd .. '(sudolist)$',
      _config.cmd .. '(sudo) (%g+)$',
      _config.cmd .. '(desudo)$',
      _config.cmd .. '(desudo) (%g+)$',
    },
    run = run,
    privilege = 5,
  }

end
