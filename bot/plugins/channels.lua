do

  -- Checks if bot was disabled on specific chat
  local function isChannelDisabled(chat_id)
    if _config.chats.disabled[chat_id] == nil then
      return false
    end
    return _config.chats.disabled[chat_id]
  end

  local function enableChannel(chat_id, msg_id)
    if _config.chats.disabled[chat_id] == nil then
      local text = _msg("Chat isn't ignored")
      return sendText(chat_id, msg_id, text)
    end
    _config.chats.disabled[chat_id] = false
    saveConfig()
    local text = _msg('I will respond to commands in this chat')
    return sendText(chat_id, msg_id, text)
  end

  local function disableChannel(chat_id, msg_id)
    _config.chats.disabled[chat_id] = true
    saveConfig()
    local text = _msg('I will ignore this chat')
    return sendText(chat_id, msg_id, text)
  end

  local function pre_process(msg)
    -- If sender is sudo then re-enable the channel
    if msg.content_.text_ == '!channel enable' and isSudo(msg.sender_user_id_) then
      msg.channel_is_enabled_ = true
      enableChannel(msg.chat_id_, msg.id_)
    end

    if isChannelDisabled(msg.chat_id_) then
      msg.content_.text_ = ''
    end

    return msg
  end

  local function run(msg, matches)
    local chat_id = msg.chat_id_

    if not _config.chats.disabled then
      _config.chats.disabled = {}
    end

    -- Enable a channel
    if matches[1] == 'enable' then
      if not msg.channel_is_enabled_ then
        enableChannel(chat_id, msg.id_)
      end
    end
    -- Disable a channel
    if matches[1] == 'disable' then
      disableChannel(chat_id, msg.id_)
    end
  end

  return {
    description = _msg('Enable or disable bot on chats.'),
    usage = {
      sudo = {
        '<code>!channel enable</code>',
        _msg('Enable bot on current chat'),
        '',
        '<code>!channel disable</code>',
        _msg('Disable bot on current chat')
      },
    },
    patterns = {
      _config.cmd .. 'channel? (enable)',
      _config.cmd .. 'channel? (disable)'
    },
    run = run,
    privileged = 5,
    pre_process = pre_process
  }

end
