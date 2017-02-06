-- TODO: Remove block when user kicked from a supergroup.

do

  -- Kicks user and re-kick if re-join
  local function banUser(chat_id, user_id, arg)
    local rank, role = getRank(user_id, chat_id)
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text

    if rank > 1 then
      text = _msg("I won't ban %s"):format(role)
    elseif rank == 0 then
      text = _msg('%s is already banned.'):format(user)
    else
      db:hset('bans' .. chat_id, user_id, arg.name)
      text = _msg('%s has been banned.'):format(user)
      td.kickChatMember(chat_id, user_id)
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- Unbans a user from the group
  local function unbanUser(chat_id, user_id, arg)
    local hash = 'bans' .. chat_id
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text

    if db:hexists(hash, user_id) then
      db:hdel(hash, user_id)
      db:hset('autokicks' .. chat_id, user_id, 0)
      text = _msg('%s has been unbanned.'):format(user)
    else
      text = _msg('%s is not banned.'):format(user)
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- Bans user on every bots managed groups
  local function globalBanUser(chat_id, user_id, arg)
    local rank, role = getRank(user_id, chat_id)
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text

    if rank > 1 then
      text = _msg("I won't globally ban %s"):format(role)
    elseif db:hexists('globalbans', user_id) then
      text = _msg('%s is already globally banned.'):format(user)
    else
      text = _msg('%s has been globally banned.'):format(user)
      db:hset('globalbans', user_id, arg.name)
      td.kickChatMember(chat_id, user_id)
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- Unbans user from global ban
  local function globalUnbanUser(chat_id, user_id, arg)
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text

    if db:hexists('globalbans', user_id) then
      text = _msg('%s has been globally unbanned.'):format(user)
      db:hdel('globalbans', user_id)
    else
      text = _msg('%s is not globally banned.'):format(user)
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- List banned user on a group
  local function banList(chat_id)
    local name = db:get('title' .. chat_id)
    local bans = db:hgetall('bans' .. chat_id)
    local title = _msg('<b>Ban list for %s</b>:\n'):format(name)
    local banned = {}
    local i = 1

    for id, name in pairs(bans) do
      banned[i] = i .. '. [<code>' .. id .. '</code>] ' .. name
      i = i + 1
    end
    if not util.emptyTable(banned) then
      local banlist = table.concat(banned, '\n')
      return title .. banlist
    else
      return _msg('There are no banned users for this group.')
    end
  end

  -- List users that's banned on every bots managed groups
  local function globalBanList()
    local dgban = db:hgetall('globalbans')
    local title = _msg('<b>Global ban list</b>\n')
    local gbanned = {}
    local i = 1

    for id, name in pairs(dgban) do
      gbanned[i] = i .. '. [<code>' .. id .. '</code>] ' .. name
      i = i + 1
    end
    if not util.emptyTable(gbanned) then
      local gbanlist = table.concat(gbanned, '\n')
      return title .. gbanlist
    else
      return _msg('There are no globally banned users.')
    end
  end

  -- getUser callback to get users identities.
  local function hammerVictim(arg, data)
    local cmd = arg.cmd
    local chat_id = arg.chat_id
    local user_id = data.id_
    local name = data.first_name_

    if data.username_ then
      name = '@' .. data.username_
    end

    local extra = {
      chat_id = arg.chat_id,
      msg_id = arg.msg_id,
      name = name
    }

    if cmd == 'kick' then
      util.kickUser(chat_id, user_id)
    elseif cmd == 'ban' then
      banUser(chat_id, user_id, extra)
    elseif cmd == 'unban' then
      unbanUser(chat_id, user_id, extra)
    elseif cmd == 'gban' then
      globalBanUser(chat_id, user_id, extra)
    elseif cmd == 'gunban' then
      globalUnbanUser(chat_id, user_id, extra)
    end
  end

  -- By-reply callback
  local function hammerByReply(arg, data)
    td.getUser(data.sender_user_id_, hammerVictim, {
        chat_id = arg.chat_id,
        msg_id = data.id_,
        cmd = arg.cmd
    })
  end

  -- Get user ids from its @username
  local function resolveUsername_cb(arg, data)
    local cmd = arg.cmd
    local user = data.type_.user_
    local chat_id = arg.chat_id
    local user_id = user.id_
    local name = user.first_name_

    if user.username_ then
      name = '@' .. user.username_
    end

    local extra = {
      chat_id = arg.chat_id,
      msg_id = arg.msg_id,
      name = name
    }

    if cmd == 'kick' then
      util.kickUser(chat_id, user_id)
    elseif cmd == 'ban' then
      banUser(chat_id, user_id, extra)
    elseif cmd == 'unban' then
      unbanUser(chat_id, user_id, extra)
    elseif cmd == 'gban' then
      globalBanUser(chat_id, user_id, extra)
    elseif cmd == 'gunban' then
      globalUnbanUser(chat_id, user_id, extra)
    end
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local rank, role = getRank(user_id, chat_id)

    -- Kick a user from current group
    if matches[1] == 'kickme' then
      util.kickUser(chat_id, user_id)
    end

    -- Moderators and higher privileged commands start here
    if rank < 2 then return end

    -- List of banned users
    if matches[1] == 'banlist' then
      if matches[2] then
        if matches[2] == 'clear' then
          db:del('bans' .. chat_id)
          return sendText(msg.chat_id_, msg.id_, _msg('Bans record for this group has been cleared.'))
        end
      else
        local banlist = banList(chat_id)
        return sendText(msg.chat_id_, msg.id_, banlist)
      end
    end

    -- List of globally banned users
    if matches[1] == 'gbanlist' then
      if matches[2] then
        if matches[2] == 'clear' then
          db:del('globalbans')
          return sendText(msg.chat_id_, msg.id_, _msg('Global bans has been cleared.'))
        end
      else
        local gbanlist = globalBanList()
        return sendText(msg.chat_id_, msg.id_, gbanlist)
      end
    end

    -- Removes a user from the group
    if matches[1] == 'kick'
        -- Bans a user from the group
        or (matches[1] == 'ban' and rank > 1)
        -- Unbans a user from the group
        or (matches[1] == 'unban' and rank > 1)
        -- Bans a user from all groups
        or (matches[1] == 'gban' and rank > 3)
        -- Unans a user from all groups
        or (matches[1] == 'gunban' and rank > 3) then

      local extra = {chat_id = chat_id, msg_id = msg.id_, cmd = matches[1]}

      if util.isReply(msg) then
        td.getMessage(chat_id, msg.reply_to_message_id_, hammerByReply, extra)
      elseif matches[2] == '@' then
        td.searchPublicChat(matches[3], resolveUsername_cb, extra)
      elseif matches[2]:match('%d+$') then
        td.getUser(matches[2], hammerVictim, extra)
      end
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Kicks or bans a user from the groups.'),
    usage = {
      moderator = {
        '<code>!kick</code>',
        _msg('Removes a user from the group by reply.'),
        '',
        '<code>!kick [username]</code>',
        _msg('Removes a user from the group by username.'),
        '',
        '<code>!kick [user_id]</code>',
        _msg('Removes a user from the group by user_id.'),
        '',
        '<code>!ban</code>',
        _msg('Bans a user from the group by reply.'),
        '',
        '<code>!ban [username]</code>',
        _msg('Bans a user from the group by username.'),
        '',
        '<code>!ban [user_id]</code>',
        _msg('Bans a user from the group by user_id.'),
        '',
        '<code>!unban</code>',
        _msg('Unbans a user from the group by reply.'),
        '',
        '<code>!unban [username]</code>',
        _msg('Unbans a user from the group by username.'),
        '',
        '<code>!unban [user_id]</code>',
        _msg('Unbans a user from the group by user_id.'),
        '',
        '<code>!gban</code>',
        _msg('Bans a user from all groups by reply.'),
        '',
        '<code>!gban [username]</code>',
        _msg('Bans a user from all groups by username.'),
        '',
        '<code>!gban [user_id]</code>',
        _msg('Bans a user from all groups by user_id.'),
        '',
        '<code>!gunban</code>',
        _msg('Removes a global ban by reply.'),
        '',
        '<code>!gunban [username]</code>',
        _msg('Removes a global ban by username.'),
        '',
        '<code>!gunban [userId]</code>',
        _msg('Removes a global ban by user_id.'),
        '',
        '<code>!banlist</code>',
        _msg('Returns list of banned users.'),
        '',
        '<code>!banlist clear</code>',
        _msg("Clear group's bans record."),
        '',
        '<code>!gbanlist</code>',
        _msg('Returns list of globally banned users.'),
        '',
        '<code>!gbanlist clear</code>',
        _msg("Clear bot's global bans record."),
        '',
      },
      user = {
        '<code>!kickme</code>',
        _msg('Removes a user from the group'),
        '',
      },
    },
    patterns = {
      _config.cmd .. '(kickme)$',
      _config.cmd .. '(kick)$',
      _config.cmd .. '(kick) (@)(.+)$',
      _config.cmd .. '(kick) (%d+)$',
      _config.cmd .. '(ban)$',
      _config.cmd .. '(ban) (@)(.+)$',
      _config.cmd .. '(ban) (%d+)$',
      _config.cmd .. '(unban)$',
      _config.cmd .. '(unban) (@)(.+)$',
      _config.cmd .. '(unban) (%d+)$',
      _config.cmd .. '(gban)$',
      _config.cmd .. '(gban) (@)(.+)$',
      _config.cmd .. '(gban) (%d+)$',
      _config.cmd .. '(gunban)$',
      _config.cmd .. '(gunban) (@)(.+)$',
      _config.cmd .. '(gunban) (%d+)$',
      _config.cmd .. '(banlist)$',
      _config.cmd .. '(banlist) (%w+)$',
      _config.cmd .. '(gbanlist)$',
      _config.cmd .. '(gbanlist) (%w+)$',
    },
    run = run
  }

end
