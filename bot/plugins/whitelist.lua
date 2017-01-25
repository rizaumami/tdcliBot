do

  local function whitelisting(chat_id, user_id, msg_id, name, cmd)
    local hash = 'whitelist'
    local is_whitelisted = db:sismember(hash, user_id)
    if cmd == 'whitelist' then
      if is_whitelisted then
        local text = _msg('%s is already whitelisted.'):format(name)
        sendText(chat_id, msg_id, text)
      else
        db:sadd(hash, user_id)
        local text = _msg('%s added to whitelist.'):format(name)
        sendText(chat_id, msg_id, text)
      end
    end
    if cmd == 'unwhitelist' then
      if not is_whitelisted then
        local text = _msg('%s is not whitelisted.'):format(name)
        sendText(chat_id, msg_id, text)
      else
        db:srem(hash, user_id)
        local text = _msg('%s removed from whitelist'):format(name)
        sendText(chat_id, msg_id, text)
      end
    end
  end

  local function getUser_cb(arg, data)
    local name = '[<code>' .. data.id_ .. '</code>] <b>' .. data.first_name_ .. '</b>'

    if data.last_name_ then
      name = name .. ' <b>' .. data.last_name_ .. '</b>'
    end

    whitelisting(arg.chat_id, data.id_, arg.msg_id, name, arg.cmd)
  end

  local function whitelistByReply(arg, data)
    td.getUser(data.sender_user_id_, getUser_cb, {
        chat_id = arg.chat_id,
        msg_id = data.id_,
        cmd = arg.cmd
    })
  end

  local function whitelistByUsername(arg, data)
    local user = data.type_.user_
    local name = '[<code>' .. user.id_ .. '</code>] <b>' .. user.first_name_ .. '</b>'

    if user.last_name_ then
      name = name .. ' <b>' .. user.last_name_ .. '</b>'
    end

    whitelisting(arg.chat_id, user.id_, arg.msg_id, name, arg.cmd)
  end

  local function pre_process(msg)
    -- If whitelist enabled
    -- Allow all sudo users even if whitelist is allowed
    if db:get('whitelist:enabled') and not isSudo(msg.sender_user_id_) then
      print('>>> Whitelist enabled and not sudo')
      -- Check if user or chat is whitelisted
      local chat_id = msg.chat_id_
      local user_id = msg.sender_user_id_
      local allowed_user = db:sismember('whitelist', user_id) or false
      local allowed_chat = db:sismember('whitelist', chat_id) or false
      if not allowed_user then
        msg.content_.text_ = ''
        print('>>> User ' .. user_id .. ' not whitelisted')
        if util.isChatMsg(msg) and not allowed_chat then
          print('>>> Chat ' .. chat_id .. ' not whitelisted')
        else
          print('>>> Chat ' .. chat_id .. ' whitelisted :)')
        end
      else
        print('>>> User ' .. user_id .. ' allowed :)')
      end
    end
    return msg
  end

  local function run(msg, matches)
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_

    if isAdmin(user_id) then
      -- Enable whitelist
      if matches[1] == 'whitelist' then
        if matches[2] == 'enable' then
          db:set('whitelist:enabled', true)
          sendText(chat_id, msg.id_, _msg('Whitelist has been enabled.'))
        elseif matches[2] == 'disable' then
          db:del('whitelist:enabled')
          sendText(chat_id, msg.id_, _msg('Whitelist has been disabled.'))
        elseif matches[2] == 'clear' then
          db:del('whitelist')
          return 'Whitelist cleared.'
        elseif matches[2] == 'chat' then
          local chat = chat_id
          if matches[3] and not util.isChatMsg(msg) then
            chat = matches[3]
          end
          db:sadd('whitelist', chat)
          local text = _msg('This chat [<code>%s</code>] has been whitelisted.'):format(chat)
          sendText(chat_id, msg.id_, text)
        end
      end
      -- Remove user from whitelist by {id|username|name|reply}
      if matches[1] == 'unwhitelist' and matches[2] == 'chat' then
        local chat = chat_id
        if matches[3] and not util.isChatMsg(msg) then
          chat = matches[3]
        end
        db:srem('whitelist', chat)
        local text = _msg('This chat [<code>' .. chat .. '</code>] removed from whitelist'):format(chat)
        sendText(chat_id, msg.id_, text)
      end
    end

    if isOwner(user_id, chat_id) then
      -- Allow user by {is|name|username|reply} to use the bot when whitelist is enabled.
      if matches[1] == 'whitelist' then
        if (msg.reply_to_message_id_ ~= 0) then
          td.getMessage(msg.chat_id_, msg.reply_to_message_id_, whitelistByReply, {
              chat_id = chat_id,
              cmd = 'whitelist'
          })
        elseif matches[2] == '@' then
          td.searchPublicChat(matches[3], whitelistByUsername, {
              chat_id = chat_id,
              msg_id = msg.id_,
              cmd = 'whitelist'
          })
        elseif matches[3] and matches[3]:match('^%d+$') then
          td.getUser(matches[3], getUser_cb, {
              chat_id = chat_id,
              msg_id = msg.id_,
              cmd = 'whitelist'
          })
        end
      end
      -- Remove users permission by {is|name|username|reply} to use the bot when whitelist is enabled.
      if matches[1] == 'unwhitelist' then
        if (msg.reply_to_message_id_ ~= 0) then
          td.getMessage(msg.chat_id_, msg.reply_to_message_id_, whitelistByReply, {
              chat_id = chat_id,
              cmd = 'unwhitelist'
          })
        elseif matches[2] == '@' then
          td.searchPublicChat(matches[3], whitelistByUsername, {
              chat_id = chat_id,
              msg_id = msg.id_,
              cmd = 'unwhitelist'
          })
        elseif matches[3] and matches[3]:match('^%d+$') then
          td.getUser(matches[3], getUser_cb, {
              chat_id = chat_id,
              msg_id = msg.id_,
              cmd = 'unwhitelist'
          })
        end
      end
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Various sudo commands.'),
    usage = {
      admin = {
        '<code>!whitelist enable</code>',
        '<code>!whitelist disable</code>',
        _msg('Enable or disable whitelist mode.'),
        '',
        '<code>!whitelist</code>',
        _msg('If type in reply, allow user to use the bot when whitelist mode is enabled.'),
        '',
        '<code>!unwhitelist</code>',
        _msg('If type in reply, remove user from whitelist.'),
        '',
        '<code>!whitelist chat</code>',
        _msg('Allow everybody on current chat to use the bot when whitelist mode is enabled.'),
        '',
        '<code>!unwhitelist chat</code>',
        _msg('Remove chat from whitelist.'),
        '',
        '<code>!whitelist [user_id]</code>',
        '<code>!whitelist [username]</code>',
        _msg('Allow user to use the bot when whitelist mode is enabled.'),
        '',
        '<code>!unwhitelist [user_id]</code>',
        '<code>!unwhitelist [username]</code>',
        _msg('Remove user from whitelist.')
      },
      owner = {
        '<code>!whitelist</code>',
        _msg('If type in reply, allow user to use the bot when whitelist mode is enabled'),
        '',
        '<code>!unwhitelist</code>',
        _msg('If type in reply, remove user from whitelist'),
        '',
        '<code>!whitelist [user_id]</code>',
        _msg('Allow user_id to use the bot when whitelist mode is enabled'),
        '',
        '<code>!whitelist [username]</code>',
        _msg('Allow username to use the bot when whitelist mode is enabled'),
        '',
        '<code>!whitelist [user_id] [chat_id]</code>',
        _msg('Allow user_id to use the bot in chat_id when whitelist mode is enabled'),
        '',
        '<code>!whitelist [username] [chat_id]</code>',
        _msg('Allow username to use the bot in chat_id when whitelist mode is enabled'),
        '',
        '<code>!unwhitelist [user_id]</code>',
        _msg('Remove user_id from whitelist'),
        '',
        '<code>!unwhitelist [username]</code>',
        _msg('Remove username from whitelist'),
        '',
        '<code>!unwhitelist [user_id] [chat_id]</code>',
        _msg('Remove user_id from chat_id whitelist'),
        '',
        '<code>!unwhitelist [username] [chat_id]</code>',
        _msg('Remove username from chat_id whitelist'),
        '',
      },
    },
    patterns = {
      _config.cmd .. '(whitelist) (%a+)$',
      _config.cmd .. '(whitelist)$',
      _config.cmd .. '(whitelist) (chat) (%d+)$',
      _config.cmd .. '(whitelist) (@)(%g+)$',
      _config.cmd .. '(whitelist)(%s)(%d+)$',
      _config.cmd .. '(unwhitelist) (%a+)$',
      _config.cmd .. '(unwhitelist)$',
      _config.cmd .. '(unwhitelist) (chat) (%d+)$',
      _config.cmd .. '(unwhitelist) (@)(%g+)$',
      _config.cmd .. '(unwhitelist)(%s)(%d+)$',
    },
    run = run,
    privilege = 5,
    pre_process = pre_process
  }

end
