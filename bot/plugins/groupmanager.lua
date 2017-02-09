do

  local settingsMsg = {
    ['unlisted']  = {
      short = _msg('This group is unlisted.'),
      enabled = _msg('This group is no longer listed in <code>!groups</code>'),
      disabled = _msg('This group is now listed in <code>!groups</code>.')
    },
    ['rtl'] = {
      short = _msg('Does not allow Arabic script or RTL characters.'),
      enabled = _msg('Users will now be removed automatically for posting Arabic script and/or RTL characters.'),
      disabled = _msg('Users will no longer be removed automatically for posting Arabic script and/or RTL characters.'),
    },
    ['squig'] = {
      short = _msg('Does not allow users whose names contain Arabic script or RTL characters.'),
      enabled = _msg('Users whose names contain Arabic script and/or RTL characters will now be removed automatically.'),
      disabled = _msg('Users whose names contain Arabic script and/or RTL characters will no longer be removed automatically.'),
    },
    ['bot'] = {
      short = _msg('Does not allow users to add bots.'),
      enabled = _msg('Non-moderators will no longer be able to add bots.'),
      disabled = _msg('Non-moderators will now be able to add bots.')
    },
    ['flood'] = {
      short = _msg('Automatically removes users who flood.'),
      enabled = _msg('Users will now be removed automatically for excessive messages. Use !antiflood to configure limits.'),
      disabled = _msg('Users will no longer be removed automatically for excessive messages.'),
    },
    ['hammer'] = {
      short = _msg('Does not acknowledge global bans.'),
      enabled = _msg('This group will no longer remove users for being globally banned.'),
      disabled = _msg('This group will now remove users for being globally banned.')
    },
    ['nokicklog'] = {
      short = _msg('Does not provide a public kick log.'),
      enabled = _msg('This group will no longer publicly log kicks and bans.'),
      disabled = _msg('This group will now publicly log kicks and bans.')
    },
    ['link'] = {
      short = _msg('Does not allow posting join links to outside groups.'),
      enabled = _msg('Users will now be removed automatically for posting outside join links.'),
      disabled = _msg('Users will no longer be removed for posting outside join links.'),
    },
    ['modrights'] = {
      short = _msg('Allows moderators to set the group photo, title, motd, and link.'),
      enabled = _msg('Moderators will now be able to set the group photo, title, motd, and link.'),
      disabled = _msg('Moderators will no longer be able to set the group photo, title, motd, and link.'),
      locked = _msg('Modrights must be unlocked for moderators to use this command.')
    }
  }

  -- Promotes a user to a moderator
  local function proMod(user_id, chat_id, arg)
    local kmod = 'moderators' .. chat_id
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text

    if db:hexists(kmod, user_id) then
      text = user .. _msg('is already a moderator.')
    else
      db:hset(kmod, user_id, arg.name)
      text = user .. _msg('is now a moderator.')
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- Demotes a moderator to a user
  local function deMod(user_id, chat_id, arg)
    local kmod = 'moderators' .. chat_id
    local user = arg.name .. ' [<code>' .. user_id .. '</code>] '
    local text

    if db:hexists(kmod, user_id) then
      db:hdel(kmod, user_id)
      text = user .. _msg('is no longer a moderator.')
    else
      text = user .. _msg('is not a moderator.')
    end
    sendText(arg.chat_id, arg.msg_id, text)
  end

  -- List groups moderators
  local function modList(chat_id)
    local name = db:get('title' .. chat_id)
    local kmod = db:hgetall('moderators' .. chat_id)
    local title = _msg('<b>Moderators for %s</b>:\n'):format(name)
    local mods = {}
    local i = 1

    for id, name in pairs(kmod) do
      mods[i] = '<b>' .. i .. '</b>. [<code>' .. id .. '</code>] ' .. name
      i = i + 1
    end
    if not util.emptyTable(mods) then
      local modlist = table.concat(mods, '\n')
      return title .. modlist
    else
      return _msg('There are currently no moderators for this group.')
    end
  end

  -- getUser callback to get users identities.
  local function promotion(arg, data)
    local cmd = arg.cmd
    local chat_id = arg.chat_id
    local user_id = data.id_
    local name = data.username_ and '@' .. data.username_ or data.first_name_
    local extra = {
      chat_id = arg.chat_id,
      msg_id = arg.msg_id,
      name = name
    }

    if cmd == 'mod' then
      proMod(user_id, chat_id, extra)
    elseif cmd == 'demod' then
      deMod(user_id, chat_id, extra)
    end
  end

  -- Callback for moderation by reply
  local function moderationByReply(arg, data)
    td.getUser(data.sender_user_id_, promotion, {
        chat_id = arg.chat_id,
        msg_id = data.id_,
        cmd = arg.cmd
    })
  end

  -- Callback for moderation by user id, resolving username.
  local function resolveMod_cb(arg, data)
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
    local extra = {
      chat_id = chat_id,
      msg_id = msg_id,
      name = '@' .. user.username_
    }

    if cmd == 'mod' then
      proMod(user_id, chat_id, extra)
    elseif cmd == 'demod' then
      deMod(user_id, chat_id, extra)
    end
  end

  -- Sets group's photo
  local function setPhoto(chat_id, msg)
    local photo = msg.content_.photo_.sizes_[0].photo_.persistent_id_
    td.changeChatPhoto(chat_id, photo)
    db:set('photo' .. chat_id, photo)
  end

  local function sendGoodWelMessage(greet, msg)
    local chat_id = msg.chat_id_
    local mtype = db:hget(greet .. chat_id, 'enabled')
    local hash = greet .. chat_id

    if mtype == 'text' and db:hexists(hash, 'text') then
      local message = db:hget(hash, 'text')
      sendText(chat_id, msg_id, message)
    elseif mtype == 'photo' and db:hexists(hash, 'photo') then
      local message = db:hget(hash, 'photo')
      local photo = message:match('^%w+')
      local caption = message:match('%w+$')
      td.sendPhoto(chat_id, msg.id_, 0, 1, nil, photo, caption)
    elseif mtype == 'sticker' and db:hexists(hash, 'sticker') then
      td.sendSticker(chat_id, msg.id_, 0, 1, nil, db:hget(hash, 'sticker'))
    elseif mtype == 'animation' and db:hexists(hash, 'animation') then
      td.sendAnimation(chat_id, msg.id_, 0, 1, nil, db:hget(hash, 'animation'))
    end
  end

  local function cron(msg)
    local flash = 'floods' .. msg.chat_id_
    if db:hgetall(flash) then
      --print(">> Delete " .. msg.chat_id_ .. "'s floods record.")
      db:del(flash)
    end
  end

--------------------------------------------------------------------------------

  local function pre_process(msg)
    -- Only process message from managed groups
    if not _config.chats.managed[msg.chat_id_] then return msg end

    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local rank, role = getRank(user_id, chat_id)
    local text = msg.content_.text_
    local action = msg.content_.ID
    local key = 'anti' .. chat_id

    -- Anti squig
    if action == "MessageChatAddMembers" or action == "MessageChatJoinByLink" then
      if db:hget(key, 'squig') == 'true' then
        td.getUser(user_id, function(a, d)
          local name = d.last_name_ and d.first_name_ .. ' ' .. d.last_name_ or d.first_name_
          if (name:match(util.char.arabic)
            or name:match(util.char.rtl_override)
            or name:match(util.char.rtl_mark)
            or name:match('^' .. util.char.braille_space)
            or name:match(util.char.braille_space .. '$')) then
            local text = _msg("You're kicked because of Arabic script and/or RTL characters on your name.")
            sendText(a.chat_id, a.msg_id, text)
            util.kickUser(a.chat_id, a.user_id)
          end
        end, {chat_id = chat_id, user_id = user_id, msg_id = msg.id_})
      end
      -- Anti bot
      if db:hget(key, 'bot') == 'true' then
        td.getUser(user_id, function(a, d)
          local name = d.username_ and d.username_:lower() or 'nousername'
          if name:match('bot$') then
            util.kickUser(a.chat_id, a.user_id)
          end
        end, {chat_id = chat_id, user_id = user_id})
      end
      -- Greetings
      if db:hexists('welcome' .. chat_id, 'enabled') then
        if rank > 0 then
          sendGoodWelMessage('welcome', msg)
        end
      end
    end
    -- Kick banned user inviter if they're invite more than 3 times
    if action == "MessageChatAddMembers" then
      if rank > 1 then
        local invited = msg.content_.members_[0].id_
        local hash = 'bans' .. chat_id
        if db:hexists(hash, invited) then
          db:hdel(hash, invited)
        end
      else
        local inviter = 'bannedinviter' .. chat_id
        db:hincrby(inviter, user_id, 1)
        local count = db:hexists(inviter, user_id)
        local autoban = db:get('autoban' .. chat_id)

        if count and tonumber(count) > tonumber(autoban) then
          util.kickUser(chat_id, user_id)
          db:set(inviter, 0)
        end
      end
      user_id = msg.content_.members_[0].id_
    end

    -- Autokick banned user
    if rank == 0 then
      util.kickUser(chat_id, user_id)
    elseif rank == 1 and text then
      -- Anti right-to-left message
      if db:hget(key, 'rtl') == 'true' and (text:match(util.char.arabic)
              or text:match(util.char.rtl_override)
              or text:match(util.char.rtl_mark)) then
        local post = msg.forward_info_ and 'forwarding' or 'posting'
        local text = _msg("You're kicked for %s Arabic script and/or RTL characters."):format(post)
        sendText(chat_id, msg_id, text)
        util.kickUser(chat_id, user_id)
      -- Anti chats/channels promotion
      elseif db:hget(key, 'link') == 'true' then
        if not util.emptyTable(msg.content_.entities_) and msg.content_.entities_[0].ID == 'MessageEntityUrl' then
          local e = msg.content_.entities_[0]
          local link = string.sub(text, e.offset_ + 1, e.length_ + e.offset_)
          local sl = link:gsub('t.me', 'telegram.me')

          td.checkChatInviteLink(sl, function(a, d)
            if not _config.chats.managed[d.chat_id_] then
              local text = _msg("You're kicked for posting an outside join link.")
              sendText(a.chat_id, a.msg_id, text)
              util.kickUser(a.chat_id, a.user_id)
            end
          end, {chat_id = chat_id, user_id = user_id, msg_id = msg.id_})
        end
      -- Words filter
      elseif not msg.forward_info_ then
        local input = text:lower()
        local filter = db:smembers('filter' .. chat_id)

        for i = 1, #filter do
          if input:match(filter[i]) then
            local text = _msg("You're kicked for using a filtered term: %s"):format(filter[i])
            sendText(chat_id, msg_id, text)
            util.kickUser(chat_id, user_id)
            break
          end
        end
      end
    end
    -- Anti flood
    if db:hget(key, 'flood') == 'true' then
      local flash = 'floods' .. chat_id
      local antiflood = 'antiflood' .. chat_id
      local ID = msg.content_.ID:lower()
      local ftype
      if ID == 'messagesticker' or ID == 'messagephoto'
                                or ID == 'messageaudio'
                                or ID == 'messagecontact'
                                or ID == 'messagelocation'
                                or ID == 'messagevoice' then
        ftype = ID:sub(8, -1)
      elseif ID == 'messagedocument' then
        local document = msg.content_.document_
        if document.mime_type_ and document.mime_type_:match('^image') then
          ftype = 'photo'
        elseif document.mime_type_ and document.mime_type_:match('^video') then
          ftype = 'video'
        else
          ftype = 'document'
        end
      else
        ftype = 'text'
      end
      db:hincrby(flash, user_id, db:hget(antiflood, ftype))
      local floods = db:hget(flash, user_id)
      if db:hexists(flash, user_id) and tonumber(floods) > 99 then
        util.kickUser(chat_id, user_id)
        db:hdel(flash, user_id)
      end
    end
    if action == "MessageChatDeleteMember" then
      if db:hexists('goodbye' .. chat_id, 'enabled') then
        if rank > 0 then
          sendGoodWelMessage('goodbye', msg)
        end
      end
    end
    -- End of pre-processing
    return msg
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local rank, role = getRank(user_id, chat_id)

    if not _config.chats.managed[chat_id] then return end

    -- Returns a description of the group
    if matches[1] == 'about' then
      local title = db:get('title' .. chat_id)
      local about = db:exists('about' .. chat_id) and db:get('about' .. chat_id) .. '\n\n' or ''
      local kanti = db:hgetall('anti' ..  chat_id)
      local anti = {}
      local i = 1

      for k, v in pairs(kanti) do
        if v == 'true' then
          anti[i] = '• ' .. settingsMsg[tostring(k)].short
          i = i + 1
        end
      end
      local rules = table.concat(anti, '\n')
      sendText(chat_id, msg.id_, '<b>' .. title .. '</b>\n' .. about .. rules)
    end

    -- Returns the group's list of rules
    if matches[1] == 'rules' then
      local title = db:get('title' .. chat_id)
      local text = 'No rules have been set for ' .. title
      local krules = 'rules' .. chat_id
      local rules = db:zrange(krules, 0, -1)
      local rule = {}

      for i = 1, #rules do
        rule[i] = '<b>' .. i .. '</b>. ' .. rules[i]
      end

      if not util.emptyTable(rule) then
        local rules = table.concat(rule, '\n')
        text = _msg('<b>%s</b> rules:\n%s'):format(title, rules)
      end
      sendText(chat_id, msg.id_, text)
    end

    -- Returns a list of moderators for the group.
    if matches[1]:match('^modlist$') then
      local modlist = modList(chat_id)
      sendText(chat_id, msg.id_, modlist)
    end

    -- Returns the group's message of the day.
    if matches[1] == 'motd' then
      local title = db:get('title' .. chat_id)
      local kmotd = db:get('motd' .. chat_id)
      local motd = _msg('No MOTD has been set for %s'):format(title)
      if db:exists('motd' .. chat_id) then
        motd = _msg('<b>MOTD for %s</b>\n%s'):format(title, kmotd)
      end
      sendText(chat_id, msg.id_, motd)
    end

    -- Returns the group's link.
    if matches[1] == 'link' then
      local title = db:get('title' .. chat_id)
      local klink = 'link' .. chat_id
      local link = _msg('No link has been set for %s'):format(title)
      if db:exists(klink) then
        link = '<b>' .. title .. '</b>\n' .. db:get(klink)
      end
      sendText(chat_id, msg.id_, link)
    end

    -- Moderator and higher privileged commands start here.
    if rank < 2 then return end

    if db:hget('anti' .. chat_id, 'modrights') == 'true' then
      sendText(chat_id, msg.id_, settingsMsg['modrights'].locked)
    else
      -- Sets the group's photo
      if matches[1] == 'setphoto' then
        if msg.content_.ID == 'MessagePhoto' then
          setPhoto(chat_id, msg)
        elseif util.isReply(msg) then
          td.getMessage(chat_id, msg.reply_to_message_id_, function(a, d)
            if d.content_.ID == 'MessagePhoto' then
              setPhoto(a, d)
            end
          end, chat_id)
        else
          text = _msg("Set group's photo by:"
              .. '\n• Upload a compressed image and give <code>!setphoto</code> as caption'
              .. '\n• Reply a picture by <code>!setphoto</code>')
          return sendText(chat_id, msg.id_, text)
        end
      end
      -- Sets the group's title
      if matches[1] == 'setname' and matches[2] then
        local title = matches[2]
        td.changeChatTitle(chat_id, title)
        _config.chats.managed[chat_id].title = title
        db:set('title' .. chat_id, matches[2])
        saveConfig()
      end
      -- Sets the group's message of the day
      if matches[1] == 'setmotd' and matches[2] then
        db:set('motd' .. chat_id, matches[2])
        sendText(chat_id, msg.id_, _msg('Successfully set the new message of the day.'))
      end
      -- Delete the group's message of the day
      if matches[1] == 'resetmotd' then
        db:del('motd' .. chat_id)
        sendText(chat_id, msg.id_, _msg('The MOTD has been cleared.'))
      end
      -- Sets the group's invite link
      if matches[1] == 'setlink' then
        td.exportChatInviteLink(chat_id, function(a, d)
          db:set('link' .. a, d.invite_link_)
        end, chat_id)
        sendText(chat_id, msg.id_, _msg('The link has been regenerated.'))
      end
    end

    -- Owner and higher privileged commands start here.
    if rank < 3 then return end

    -- Sets group's description
    if matches[1] == 'setabout' and matches[2] then
      local about = matches[2]
      if util.isSuperGroup(chat_id) then
        td.changeChannelAbout(chat_id, about)
      end
      db:set('about' .. chat_id, about)
      sendText(chat_id, msg.id_, _msg('Successfully set the new description.'))
    end

    -- Delete group's description
    if matches[1] == 'resetabout' then
      if util.isSuperGroup(chat_id) then
        td.changeChannelAbout(chat_id, nil)
      end
      db:del('about' .. chat_id)
      sendText(chat_id, msg.id_, _msg('The groups description has been cleared.'))
    end

    -- Sets the group's rules.
    -- Rules will be automatically numbered. Separate rules with a new line.
    if matches[1] == 'setrules' then
      local text = _msg('Please specify the new rules.')
      if matches[2] then
        local input = util.trim(matches[2]) .. '\n'
        local gname = db:get('title' .. chat_id)
        local title = _msg('<b>Rules for %s</b>:\n'):format(gname)
        local rules = {}
        local i = 1

        for l in input:gmatch('(.-)\n') do
          print(l)
          rules[i] = '<b>' .. i .. '</b>. ' .. util.trim(l)
          db:zadd('rules' .. chat_id, i, util.trim(l))
          i = i + 1
        end
        text = table.concat(rules, '\n')
      end
      sendText(chat_id, msg.id_, text)
    end

    -- Inserts a single rule as [num].
    -- If [num] is a number for which there is no rule, adds a rule indexed higher
    -- than the highest-indexed rule.
    if matches[1] == 'addrule' then
      local krules = 'rules' .. chat_id
      local text = _msg('Usage: <code>%saddrule [num] [rule]</code>'):format(_config.cmd)

      if matches[2]:match('%d+') then
        local rule_num = tonumber(matches[2])
        if not rule_num then
          text = _msg('Please specify where you want to add the new rule.')
        elseif not matches[3] then
          text = 'Please specify the new rule.'
        else
          local rules = db:zrange(krules, 0, -1)

          if not rules[rule_num] then
            rule_num = #rules + 1
          end
          table.insert(rules, rule_num, matches[3])
          db:del(krules)
          for k, v in pairs(rules) do
            db:zadd(krules, k, v)
          end
          text = '<b>' .. rule_num .. '</b>. ' .. matches[3]
        end
      end
      sendText(chat_id, msg.id_, text)
    end

    -- Inserts a single rule as [num].
    -- If [num] is a number for which there is no rule, adds a rule indexed higher
    -- than the highest-indexed rule.
    if matches[1] == 'changerule' then
      local krules = 'rules' .. chat_id
      local rules = db:zrange(krules, 0, -1)
      local text = _msg('Usage: <code>%schange [num] [rule]</code>'):format(_config.cmd)

      if matches[2]:match('%d+') then
        local rule_num = tonumber(matches[2])
        if not rule_num then
          text = _msg('Please specify which rule you want to change.')
        elseif not matches[3] then
          text = _msg('Please specify the new rule.')
        elseif not rules[rule_num] then
          text = _msg('There is no rule with that number.')
        else
          db:zremrangebyscore(krules, rule_num, rule_num)
          db:zadd(krules, rule_num, matches[3])
          text = '<b>' .. rule_num .. '</b>. ' .. matches[3]
        end
      end
      sendText(chat_id, msg.id_, text)
    end

    -- Delete groups rule
    if matches[1] == 'resetrules' and matches[2] then
      local krules = 'rules' .. chat_id
      local rules = db:zrange(krules, 0, -1)
      local text
      if matches[2]:match('%d+') then
        local rule_num = tonumber(matches[2])
        if rules[rule_num] then
          db:zremrangebyscore(krules, rule_num, rule_num)
          text = _msg('That rule has been deleted.')
        else
          text = _msg('There is no rule with that number.')
        end
      elseif matches[2] == 'all' then
        db:del(krules)
        text = _msg('The custom rules have been cleared.')
      end
      sendText(chat_id, msg.id_, text)
    end

    -- Adds or removes a word filter, or lists all word filters.
    -- Users are automatically kicked after using a filtered term.
    if matches[1] == 'filter' then
      local kfilter = 'filter' .. chat_id
      local text
      if matches[2] then
        local input = matches[2]:lower()
        if db:sismember(kfilter, input) then
          db:srem(kfilter, input)
          text = _msg('That term has been removed from the filter.')
        else
          db:sadd(kfilter, input)
          text = _msg('That term has been added to the filter.')
        end
      else
        local filter = db:smembers('filter' .. chat_id)
        local title = util.escapeHtml(db:get('title' .. chat_id))
        local words = util.escapeHtml(table.concat(filter, '\n• '))
        text = _msg('<b>Filtered Terms for %s</b>:\n• %s'):format(title, words)
        if #words < 2 then
          text = _msg('There are currently no filtered terms.')
        end
      end
      sendText(chat_id, msg.id_, text)
    end

    -- Get groups configuration file.
    if matches[1] == 'getconfig' then
      local name = db:get('title' .. chat_id)
      local cfg = {}
      local keys = db:keys('*' .. chat_id)

      for i = 1, #keys do
        local ktype = db:type(keys[i])
        local key = keys[i]:match('%w+')
        if ktype == "string" then
          cfg[key] = db:get(keys[i])
        elseif ktype == "list" then
          cfg[key] = db:lrange(keys[i], 0, -1)
        elseif ktype == "hash" then
          cfg[key] = db:hgetall(keys[i])
        elseif ktype == "set" then
          cfg[key] = db:smembers(keys[i])
        elseif ktype == "sortedset" then
          cfg[key] = db:zrange(keys[i], 0, -1)
        end
      end
      local file = '/tmp/config' .. chat_id .. '.lua'
      saveConfig(cfg, file)
      td.sendDocument(_config.bot.id, 0, 0, 1, nil, file, name)
    end

    -- Clear moderator list. Demotes all moderators to user.
    if matches[1] == 'modlist clear' then
      db:del('moderators' .. chat_id)
      return sendText(chat_id, msg.id_, _msg('All moderators of this group has been demoted.'))
    end

    -- Returns a list of antiflood values or sets one.
    if matches[1] == 'antiflood' then
      local kanti = 'antiflood' .. chat_id
      local text

      if (db:hget('anti' .. chat_id, 'flood') == 'false') then
        text = _msg('Anti flood is not enabled.\nUse `!lock flood` to enable it.')
        return sendText(chat_id, msg.id_, text, 1, 'md')
      end
      if matches[3] and matches[3]:match('%d') then
        local key = matches[2]
        local val = tonumber(matches[3])
        db:hset(kanti, key, val)
        local kupper = key:gsub('^%l', string.upper)
        text = _msg('*%s* messages are now worth *%s* points.'):format(kupper, val)
      else
        local antiflood = db:hgetall(kanti)
        local fcount = {}
        local i = 1

        for k, v in pairs(antiflood) do
          fcount[i] = '• ' .. k .. ': `' .. v .. '`'
          i = i + 1
        end
        text = table.concat(fcount, '\n')
      end
      sendText(chat_id, msg.id_, text, 1, 'md')
    end

    if matches[1] == 'autoban' and matches[2]:match('%d+') then
      local count = tonumber(matches[2])
      local text = _msg('Users will now be automatically banned after <b>%s</b> automatic kick(s).'):format(count)
      db:set('autoban' .. chat_id, count)
      sendText(chat_id, msg.id_, text)
    end

    -- Removes this group from the group listing.
    if matches[1] == 'private' then
      _config.chats.managed[chat_id].unlisted = true
      saveConfig()
      sendText(msg.chat_id_, msg.id_, settingsMsg['unlisted'].enabled)
    end

    -- List this group in the group listing.
    if matches[1] == 'public' then
      _config.chats.managed[chat_id].unlisted = false
      saveConfig()
      sendText(msg.chat_id_, msg.id_, settingsMsg['unlisted'].disabled)
    end

    -- returns group's settings
    if matches[1] == 'settings' then
      local kanti = db:hgetall('anti' .. chat_id)
      local antiflood = db:hgetall('antiflood' .. chat_id)
      local autoban = 'Autoban: `' .. db:get('autoban' .. chat_id) .. '`\n'
      local welcome = db:hget('welcome' .. chat_id, 'enabled') and 'Welcome: ' .. db:hget('welcome' .. chat_id, 'enabled') or 'Welcome: disabled'
      local goodbye = db:hget('goodbye' .. chat_id, 'enabled') and 'Goodbye: ' .. db:hget('goodbye' .. chat_id, 'enabled') or 'Goodbye: disabled'
      local status, asetts, fsetts = nil, {}, {}
      local i, n = 1, 1

      for k, v in pairs(kanti) do
        if v == 'true' then
          status = '✅ '
        else
          status = '❌ '
        end
        asetts[i] = status .. 'anti-' .. k
        i = i + 1
      end
      local lock = table.concat(asetts, '\n')

      for k, v in pairs(antiflood) do
        fsetts[n] = '• ' .. k .. ': `' .. v .. '`'
        n = n + 1
      end
      local fcount = table.concat(fsetts, '\n')
      local text = "*Group's settings*:\n" .. autoban .. welcome
                .. '\n' .. goodbye .. '\n' .. lock .. '\n\n*Flood count*:\n' .. fcount
      sendText(chat_id, msg.id_, text, 1, 'md')
    end

    -- Restrict items
    if matches[1] == 'lock' and matches[2] then
      local kanti = 'anti' .. chat_id
      local key = matches[2]
      if key == 'bot' then
        db:hset(kanti, 'bot', 'true')
      elseif key == 'flood' then
        db:hset(kanti, 'flood', 'true')
      elseif key == 'hammer' then
        db:hset(kanti, 'hammer', 'true')
      elseif key == 'link' then
        db:hset(kanti, 'link', 'true')
      elseif key == 'modrights' then
        db:hset(kanti, 'modrights', 'true')
      elseif key == 'rtl' then
        db:hset(kanti, 'rtl', 'true')
      elseif key == 'squig' then
        db:hset(kanti, 'squig', true)
      end
      sendText(chat_id, msg.id_, settingsMsg[key].enabled)
    end

    -- Allow items
    if matches[1] == 'unlock' and matches[2] then
      local kanti = 'anti' .. chat_id
      local key = matches[2]
      if key == 'bot' then
        db:hset(kanti, 'bot', 'false')
      elseif key == 'flood' then
        db:hset(kanti, 'flood', 'false')
      elseif key == 'hammer' then
        db:hset(kanti, 'hammer', 'false')
      elseif key == 'link' then
        db:hset(kanti, 'link', 'false')
      elseif key == 'modrights' then
        db:hset(kanti, 'modrights', 'false')
      elseif key == 'rtl' then
        db:hset(kanti, 'rtl', 'false')
      elseif key == 'squig' then
        db:hset(kanti, 'squig', false)
      end
      sendText(chat_id, msg.id_, settingsMsg[key].disabled)
    end

    -- mod = promotes a user to a moderator
    -- demod = demote a moderator to a user
    if matches[1] == 'mod' or matches[1] == 'demod' then
      local extra = {chat_id = msg.chat_id_, msg_id = msg.id_, cmd = matches[1]}

      if util.isReply(msg) then
        td.getMessage(chat_id, msg.reply_to_message_id_, moderationByReply, extra)
      elseif matches[2] == '@' then
        td.searchPublicChat(matches[3], resolveMod_cb, extra)
      elseif matches[2]:match('%d+$') then
        td.getUser(matches[2], promotion, extra)
      end
    end

    -- Sets welcome and/or goodbye message
    if matches[1] == 'setwelcome' or matches == 'setgoodbye' then
      local greet = matches[1]:sub(4, -1)
      local kgreet = greet .. chat_id
      local message = matches[2] or ''

      if util.isReply(msg) then
        td.getMessage(chat_id, msg.reply_to_message_id_, function(a, d)
          local ID = d.content_.ID
          local gmsg, mtype
          if ID == 'MessagePhoto' then
            gmsg = d.content_.photo_.sizes_[0].photo_.persistent_id_ .. ' ' .. a.msg
            mtype = 'photo'
          elseif ID == 'MessageSticker' then
            gmsg = d.content_.sticker_.sticker_.persistent_id_
            mtype = 'sticker'
          elseif ID == 'MessageAnimation' then
            gmsg = d.content_.animation_.animation_.persistent_id_
            mtype = 'animation'
          end
          if gmsg then
            db:hset(a.greet .. a.chat_id, mtype, gmsg)
            db:hset(a.greet .. a.chat_id, 'enabled', mtype)
            local text = _msg('New media setted as %s message!'):format(a.greet)
            sendText(a.chat_id, d.id_, text)
          else
            sendText(a.chat_id, a.msg_id, _msg('Only use animations, images, or stickers as a welcome message!'))
          end
        end, {chat_id = chat_id, msg_id = msg_id, greet = greet, msg = message})
      elseif message then
        db:hset(kgreet, 'text', message)
        sendText(chat_id, msg.id_, _msg('Custom welcome message saved!'))
      else
        text = _msg("Set group's greetings by:"
            .. '\n• Type <code>!setwelcome [message]</code>'
            .. '\n• Reply a picture by <code>!setwelcome [message]</code>'
            .. '\n• Reply an animation or a sticker by <code>!setwelcome</code>')
        sendText(chat_id, msg.id_, text)
      end
    end
    -- Sets welcome and/or goodbye message
    if matches[1] == 'resetwelcome' or matches == 'resetgoodbye' then
      local greet = matches[1]:sub(6, -1)
      local text = _msg('%s has been disabled.'):format(greet)
      db:hset(greet .. chat_id, 'disabled', 'false')
      sendText(chat_id, msg.id_, text:gsub('^%l', string.upper))
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Plugin to manage a chat group.'),
    usage = {
      moderator = {
        '<code>!setabout [about]</code>',
        _msg("Sets group's description."),
        '',
        '<code>!resetabout</code>',
        _msg("Delete group's description."),
        '',
        '<code>!setmotd [motd]</code>',
        _msg("Sets the group's message of the day. HTML is supported."),
        '',
        '<code>!resetmotd</code>',
        _msg("Delete the group's message of the day."),
        '',
        '<code>!setname [name]</code>',
        _msg("Sets group's title."),
        '',
        '<code>!setphoto</code>',
        _msg("Sets group's photo."),
        '',
        '<code>!setrules [rules]</code>',
        _msg("Sets the group's rules. Rules will be automatically numbered. Separate rules with a new line. HTML is supported."),
        '',
        '<code>!addrule [num] [rule]</code>',
        _msg('Inserts a single rule as <code>num</code>. If <code>num</code> is a number for which there is no rule, adds a rule indexed higher than the highest-indexed rule.'),
        '',
        '<code>!changerule [num] [rule]</code>',
        _msg('Changes a single rule. If <code>num</code> is a number for which there is no rule, adds a rule indexed higher than the highest-indexed rule.'),
        '',
        '<code>!resetrules [num]</code>',
        _msg('Delete a single rule.'),
        '',
        '<code>!resetrules [num]</code>',
        _msg('Delete a whole rules.'),
        '',
        '<code>!setlink</code>',
        _msg("Sets the group's invite link."),
        '',
        '<code>!filter</code>',
        _msg('Lists all word filters. Users are automatically kicked after using a filtered term.'),
        '',
        '<code>!filter [word]</code>',
        _msg('Adds or removes a word filters. Users are automatically kicked after using a filtered term.'),
        '',
        '<code>!mod</code>',
        _msg('Promotes a user to a moderator by reply.'),
        '',
        '<code>!mod [username]</code>',
        _msg('Promotes a user to a moderator by username.'),
        '',
        '<code>!mod [user_id]</code>',
        _msg('Promotes a user to a moderator by user_id.'),
        '',
        '<code>!demod</code>',
        _msg('Demotes a moderator to a user by reply.'),
        '',
        '<code>!demod [username]</code>',
        _msg('Demotes a moderator to a user by username.'),
        '',
        '<code>!demod [user_id]</code>',
        _msg('Demotes a moderator to a user by user_id.'),
        '',
        '<code>!modlist clear</code>',
        _msg('Demotes all moderators to users.'),
        '',
        '<code>!lock bot</code>',
        _msg('Prevents the addition of bots by non-moderators.'),
        '',
        '<code>!lock flood</code>',
        _msg('Prevents flooding by rate-limiting messages per user.'),
        '',
        '<code>!lock hammer</code>',
        _msg('Denied globally banned users to enter this group.'),
        '',
        '<code>!lock link</code>',
        _msg('Automatically removes users who post Telegram links to outside groups.'),
        '',
        '<code>!lock modrights</code>',
        _msg('Denied moderators to set the group photo, title, motd, and link.'),
        '',
        '<code>!lock rtl</code>',
        _msg('Automatically removes users who post Arabic script or RTL characters.'),
        '',
        '<code>!unlock bot</code>',
        _msg('Allow the addition of bots by non-moderators.'),
        '',
        '<code>!unlock flood</code>',
        _msg('Will not rate-limiting messages per user.'),
        '',
        '<code>!unlock hammer</code>',
        _msg('Allow globally banned users to enter this group.'),
        '',
        '<code>!unlock link</code>',
        _msg('Allow users to post Telegram links to outside groups.'),
        '',
        '<code>!unlock modrights</code>',
        _msg('Allows moderators to set the group photo, title, motd, and link.'),
        '',
        '<code>!unlock rtl</code>',
        _msg('Allow users to posting Arabic script and/or RTL characters.'),
        '',
        '<code>!group settings</code>',
        _msg("Returns group's settings."),
        '',
        '<code>!getconfig</code>',
        _msg('Get groups configuration file.'),
        '',
        '<code>!autoban [num]</code>',
        _msg('Sets autokicks number before a user be banned.'),
        '',
        '<code>!antiflood</code>',
        _msg('Returns a list of antiflood values.'),
        '',
        '<code>!antiflood [key] [num]</code>',
        _msg('Sets antiflood values.'),
        '',
        '<code>!private [enable]</code>',
        _msg('Removes this group from the group listing.'),
        '',
        '<code>!private [disable]</code>',
        _msg('List this group to the group listing.'),
        '',
      },
      user = {
        '<code>!about</code>',
        _msg('Returns a description of the group.'),
        '',
        '<code>!motd</code>',
        _msg("Returns the group's message of the day."),
        '',
        '<code>!rules</code>',
        _msg("Returns the group's list of rules, or a specific rule."),
        '',
        '<code>!modlist</code>',
        _msg('Returns a list of moderators for the group.'),
        '',
        '<code>!link</code>',
        _msg("Returns the group's link."),
        '',
      },
    },
    patterns = {
      _config.cmd .. '(about)$',
      _config.cmd .. '(setabout) (.*)$',
      _config.cmd .. '(resetabout)$',
      _config.cmd .. '(motd)$',
      _config.cmd .. '(setmotd) (.*)$',
      _config.cmd .. '(resetmotd)$',
      _config.cmd .. '(setname) (.*)$',
      _config.cmd .. '(setphoto)$',
      _config.cmd .. '(rules)$',
      _config.cmd .. '(setrules) (.*)$',
      _config.cmd .. '(addrule) (%d+) (.*)$',
      _config.cmd .. '(changerule) (%d+) (.*)$',
      _config.cmd .. '(resetrules) (.*)$',
      _config.cmd .. '(link)$',
      _config.cmd .. '(setlink)$',
      _config.cmd .. '(filter)$',
      _config.cmd .. '(filter) (.*)$',
      _config.cmd .. '(mod)$',
      _config.cmd .. '(mod) (@)(.+)$',
      _config.cmd .. '(mod) (%d+)$',
      _config.cmd .. '(demod)$',
      _config.cmd .. '(demod) (@)(.+)$',
      _config.cmd .. '(demod) (%d+)$',
      _config.cmd .. '(modlist)$',
      _config.cmd .. '(modlist clear)$',
      _config.cmd .. '(lock) (%w+)$',
      _config.cmd .. '(unlock) (%w+)$',
      _config.cmd .. '(settings)$',
      _config.cmd .. '(getconfig)$',
      _config.cmd .. '(autoban) (%d+)$',
      _config.cmd .. '(antiflood)$',
      _config.cmd .. '(antiflood) (%w+) (%d+)$',
      _config.cmd .. '(private)$',
      _config.cmd .. '(public)$',
      _config.cmd .. '(setwelcome)$',
      _config.cmd .. '(setwelcome) (.*)$',
      _config.cmd .. '(resetwelcome)$',
      _config.cmd .. '(setgoodbye)$',
      _config.cmd .. '(setgoodbye) (.*)$',
      _config.cmd .. '(setgoodbye)$',
    },
    run = run,
    pre_process = pre_process,
    cron = cron
  }

end
