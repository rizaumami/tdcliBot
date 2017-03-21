do

  -- ChatMemberStatusEditor users is moderator
  local function fetchMods(chat_id, members)
    for _, v in util.pairsByKeys(members) do
      local kstatus
      if v.status_.ID == 'ChatMemberStatusEditor' then
        kstatus = 'moderators'
      elseif v.status_.ID == 'ChatMemberStatusCreator' then
        kstatus = 'creator'
      --elseif v.status_.ID == 'ChatMemberStatusMember' then
        --kstatus = 'members'
      end
      if kstatus then
        td.getUser(v.user_id_, function(a, d)
          local name = d.username_ and '@' .. d.username_ or d.first_name_
          db:hset(a.kstatus .. a.chat_id, d.id_, name)
        end, {chat_id = chat_id, kstatus = kstatus})
      end
    end
  end

  -- Promotes a user to an administrator
  local function admin(user_id, arg)
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text

    if _config.administrators[user_id]  then
      text = _msg('%s is already an administrator.'):format(user)
    else
      _config.administrators[user_id] = arg.name
      saveConfig()
      text = _msg('%s is now an administrator.'):format(user)
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- Demotes an administrator to a user
  local function deAdmin(user_id, arg)
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text

    if _config.administrators[user_id] then
      _config.administrators[user_id] = nil
      saveConfig()
      text = _msg('%s is no longer an administrator.'):format(user)
    else
      text = _msg('%s is not an administrator.'):format(user)
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- Promotes a user as an owner of the group
  local function setOwner(user_id, chat_id, arg)
    local title = db:get('title' .. chat_id)
    local kowner = 'owner' .. chat_id
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text = _msg('%s is already the owner of <b>%s</b>'):format(user, title)

    if not db:hexists(kowner, user_id) then
      db:del(kowner)
      db:hset(kowner, user_id, arg.name)
      text = _msg('%s is the owner of <b>%s</b>'):format(user, title)
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- Demotes an owner to a user
  local function deOwner(msg)
    local chat_id = msg.chat_id_
    local user_id = _config.bot.id
    local title = db:get('title' .. chat_id)
    local kowner = 'owner' .. chat_id
    local text

    if db:hexists(kowner, user_id) then
      text = _msg('There are currently no owner for this group.')
    else
      local owner = db:hgetall(kowner)
      local user
      for k, v in pairs(owner) do
        user = v .. ' [<code>' .. k .. '</code>] '
      end
      db:del(kowner)
      db:hset(kowner, user_id, user_id)
      text = _msg('%s is no longer the owner of <b>%s</b>.\nThis group is temporarily owned by me.'):format(user, title)
    end
    sendText(chat_id, msg.id_, text)
  end

  -- getUser callback to get users identities.
  local function administration(arg, data)
    local cmd = arg.cmd
    local chat_id = arg.chat_id
    local user_id = data.id_
    arg.name = data.username_ and '@' .. data.username_ or data.first_name_

    if cmd == 'admin' then
      admin(user_id, arg)
    elseif cmd == 'deadmin' then
      deAdmin(user_id, arg)
    elseif cmd == 'setowner' then
      setOwner(user_id, chat_id, arg)
    end
  end

  -- Administration by reply
  local function adminByReply(arg, data)
    arg.msg_id = data.id_,
    td.getUser(data.sender_user_id_, administration, arg)
  end

  -- Administration by user id, resolving username.
  local function resolveAdmin_cb(arg, data)
    local exist, err = util.checkUsername(data)
    local username = arg.username
    local chat_id = arg.chat_id
    local msg_id = arg.msg_id

    if not exist then
      return sendText(chat_id, msg_id, _msg(err):format(username))
    end

    local user = data.type_.user_
    local cmd = arg.cmd
    local user_id = user.id_
    arg.name = '@' .. user.username_

    if cmd == 'admin' then
      admin(user_id, arg)
    elseif cmd == 'deadmin' then
      deAdmin(user_id, arg)
    elseif cmd == 'setowner' then
      setOwner(user_id, chat_id, arg)
    end
  end

  -- Adds a group to the administration system.
  local function addGroup(chat_id, user_id)
    if _config.chats.managed[chat_id] then
      text = _msg('I am already administrating this group.')
    else
      _config.chats.managed[chat_id] = {unlisted = false}
      saveConfig()
      db:set('log' .. chat_id, user_id)
      db:set('autoban' .. chat_id, 3)
      db:hmset('anti' .. chat_id,
               'bot', 'false',
               'flood', 'true',
               'hammer', 'false',
               'link', 'false',
               'modrights', 'false',
               'rtl', 'true',
               'squig', 'false'
      )
      db:hmset('antiflood' .. chat_id,
               'text', 5,
               'voice', 5,
               'audio', 5,
               'contact', 5,
               'photo', 10,
               'video', 10,
               'location', 10,
               'document', 10,
               'sticker', 20
      )
      if util.isSuperGroup(chat_id) then
        td.getChannelFull(chat_id, function(a, d)
          db:set('about' .. a, d.about_)
          db:set('username' .. a, d.channel_.username_ or false)
          if d.invite_link_ then
            db:set('link' .. a, d.invite_link_)
            _config.chats.managed[a].link = d.invite_link_
            saveConfig()
          end
        end, chat_id)

        td.getChannelMembers(chat_id, 'Administrators', 0, 200, function(a, d)
          fetchMods(a, d.members_)
        end, chat_id)
      else
        td.getGroupFull(chat_id, function(a, d)
          if d.invite_link_ then
            db:set('link' .. a, d.invite_link_)
          end
          fetchMods(a, d.members_)
        end, chat_id)
      end
      -- Newly created group don't have an invite link yet
      if not db:exists('link' .. chat_id) then
        td.exportChatInviteLink(chat_id, function(a, d)
          db:set('link' .. a, d.invite_link_)
        end, chat_id)
      end
      -- Get chats title
      td.getChat(chat_id, function(a, d)
        db:set('title' .. a, d.title_)
        _config.chats.managed[a].title = d.title_
        saveConfig()
      end, chat_id)
      -- Set group owner
      local extra = {chat_id = chat_id, msg_id = 0, cmd = 'setowner'}
      td.getUser(user_id, administration, extra)
      text = _msg('I am now administrating this group.')
    end
    return sendText(chat_id, 0, text)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)
    local rank, role = getRank(user_id, chat_id)
    local text

    -- Print the owner of current group.
    if matches[1] == 'owner' then
      local title = db:get('title' .. chat_id)
      local owner = db:hgetall('owner' .. chat_id)
      local text
      for k, v in pairs(owner) do
        text = _msg('%s [<code>%s</code>] is the owner of <b>%s</b>'):format(v, k, title)
      end
      return sendText(chat_id, msg.id_, text)
    end

    -- Administrator and higher privileged commands start here
    if rank < 4 then return end

    -- Returns a list of administrators
    if matches[1] == 'adminlist' then
      local text, admin = nil, ''

      for id, name in pairs(_config.administrators) do
        admin = admin .. '• [<code>' .. id .. '</code>] ' .. name
      end
      if #admin > 1 then
        text = '<b>Administrators</b>:\n' .. admin
      else
        text = _msg('There are currently no administrators.')
      end
      return sendText(chat_id, msg.id_, text)
    end

    -- Returns a list of all administrated groups.
    if matches[1] == 'groups' then
      local managed = _config.chats.managed

      if util.emptyTable(managed) then
        sendText(chat_id, msg.id_, _msg('There are no groups.'))
      else
        local groups = {}
        local title = '<b>Groups</b>:\n'
        local i = 1
        for k, v in pairs(managed) do
          if not v.unlisted then
            if v.link or v.title then
              groups[i] = '• <a href="' .. v.link .. '">' .. util.escapeHtml(v.title) .. '</a>'
              i = i + 1
            end
          end
        end
        local list = table.concat(groups, '\n')
        return util.apiSendMessage(msg, title .. list, 'HTML', true)
      end
    end

    -- Adds a group to the administration system.
    if matches[1] == 'gadd' then
      if _config.chats.managed[chat_id] then
        return sendText(chat_id, msg.id_, _msg('I am already administrating this group.'))
      else
        addGroup(chat_id, user_id)
      end
    end

    -- Removes a group from the administration system.
    if matches[1] == 'grem' then
      if _config.chats.managed[chat_id] then
        _config.chats.managed[chat_id] = nil
        saveConfig()
        local keys = db:keys('*' .. chat_id)
        for i = 1, #keys do
          db:del(keys[i])
        end
        text = _msg('I am no longer administrating this group.')
      else
        text = _msg('I do not administrate this group.')
      end
      return sendText(chat_id, msg.id_, text)
    end

    -- Demotes an owner to a user
    if matches[1] == 'deowner' then
      return deOwner(msg)
    end

    -- Sends message to all of the managed groups
    if matches[1] == 'broadcast' then
      local groups = _config.chats.managed
      for k, v in pairs(groups) do
        sendText(k, 0, matches[2])
      end
    end

    -- Promotes a user to an administrator
    if matches[1] == 'admin' and rank == 5
      -- Demotes an administrator to a user
      or matches[1] == 'deadmin' and rank == 5
      -- Promotes a user to the owner
      or matches[1] == 'setowner' then

      local extra = {chat_id = chat_id, msg_id = msg.id_, cmd = matches[1]}

      if util.isReply(msg) then
        td.getMessage(chat_id, msg.reply_to_message_id_, function(a, d)
          a.msg_id = d.id_
          td.getUser(d.sender_user_id_, administration, a)
        end, extra)
      elseif matches[2] then
        if matches[2] == '@' then
          td.searchPublicChat(matches[3], resolveAdmin_cb, extra)
        elseif matches[2]:match('%d+$') then
          td.getUser(matches[2], administration, extra)
        end
      end
    end

    if not _config.sudoers[user_id] then return end

    -- Create a new group chat
    if matches[1] == 'mkgroup' then
      if not matches[2] then
        return sendText(chat_id, msg.id_, _msg('Please specify the new group title.'))
      elseif matches[2] and #matches[2] > 255 then
        return sendText(chat_id, msg.id_, _msg("Group's title is limited to 255 characters."))
      end
      local members = {_config.bot.id, [0] = user_id}
      td.createNewGroupChat(members, matches[2], function(a, d)
        addGroup(d.chat_id_, a)
      end, user_id)
    end

    -- Create a new supergroup chat
    if matches[1] == 'mksupergroup' then
      local text
      if not matches[2] then
        text = _msg('Please specify the new group title.')
      elseif matches[2] and #matches[2] > 255 then
        text = _msg("Group's title is limited to 255 characters.")
      elseif not matches[3] then
        text = _msg('Please specify the new group description.')
      elseif matches[3] and #matches[3] > 255 then
        text = _msg("Group's description is limited to 255 characters.")
      end

      if text then
        sendText(chat_id, msg.id_, _msg('Please specify the new group title.'))
      else
        td.createNewChannelChat(matches[2], 1, matches[3], function(a, d)
          addGroup(d.message_.chat_id_, a)
        end, user_id)
      end
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Plugin to manage chat groups.'),
    usage = {
      admin = {
        'https://telegra.ph/Administration-03-10',
        --'<code>!mkgroup [title]</code>',
        --_msg('Creates new group chat.'),
        --'',
        --'<code>!mksupergroup [title] [about]</code>',
        --_msg('Creates new supergroup chat.'),
        --'',
        --'<code>!gadd</code>',
        --_msg('Adds a group to the administration system.'),
        --'',
        --'<code>!grem</code>',
        --_msg('Removes a group from the administration system.'),
        --'',
        --'<code>!groups</code>',
        --_msg('Returns a list of all administrated groups.'),
        --'',
        --'<code>!admin</code>',
        --_msg('Promotes a user to an administrator by reply.'),
        --'',
        --'<code>!admin [username]</code>',
        --_msg('Promotes a user to an administrator by username.'),
        --'',
        --'<code>!admin [user_id]</code>',
        --_msg('Promotes a user to an administrator by user_id.'),
        --'',
        --'<code>!adminlist</code>',
        --_msg('Returns a list of administrators.'),
        --'',
        --'<code>!deadmin</code>',
        --_msg('Demotes an administrator to a user by reply.'),
        --'',
        --'<code>!deadmin [username]</code>',
        --_msg('Demotes an administrator to a user by username.'),
        --'',
        --'<code>!deadmin [user_id]</code>',
        --_msg('Demotes an administrator to a user by user_id.'),
        --'',
        --'<code>!setowner</code>',
        --_msg('Promotes a user to the owner by reply.'),
        --'',
        --'<code>!setowner [username]</code>',
        --_msg('Promotes a user to the owner by username.'),
        --'',
        --'<code>!setowner [user_id]</code>',
        --_msg('Promotes a user to the owner by user_id.'),
        --'',
        --'<code>!deowner</code>',
        --_msg("Demotes the group's owner to a user and temporarily replaced by the bot."),
        --'',
        --'<code>!broadcast [text]</code>',
        --_msg("Sends message to all of the managed groups."),
        --'',
      },
      user = {
        '<code>!owner</code>',
        _msg('Returns the owner of current group.'),
        '',
      },
    },
    patterns = {
      _config.cmd .. '(mkgroup)$',
      _config.cmd .. '(mksupergroup)$',
      _config.cmd .. '(gadd)$',
      _config.cmd .. '(grem)$',
      _config.cmd .. '(groups)$',
      _config.cmd .. '(admin)$',
      _config.cmd .. '(admin) (@)(.+)$',
      _config.cmd .. '(admin) (%d+)$',
      _config.cmd .. '(adminlist)$',
      _config.cmd .. '(deadmin)$',
      _config.cmd .. '(deadmin) (@)(.+)$',
      _config.cmd .. '(deadmin) (%d+)$',
      _config.cmd .. '(owner)$',
      _config.cmd .. '(setowner)$',
      _config.cmd .. '(setowner) (@)(.+)$',
      _config.cmd .. '(setowner) (%d+)$',
      _config.cmd .. '(deowner)$',
      _config.cmd .. '(broadcast) (.*)$',
    },
    run = run
  }

end
