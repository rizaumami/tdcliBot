do

  local function report(chat_id, msg_id, reporter, description)
    local text = _msg('• <b>Message reported by</b>: %s'):format(reporter)
    local link = db:get('link' .. chat_id)
    local guname = db:get('username' .. chat_id)
    local title = util.escapeHtml(db:get('title' .. chat_id))
    local logchat = db:get('log' .. chat_id)

    if link then
      text = text .. _msg('\n• <b>Group</b>: %s (%s)'):format(title, link)
    else
      text = text .. _msg('\n• <b>Group</b>: %s'):format(title)
    end
    if guname and guname ~= 'false' then
      text = text .. _msg('\n• Go to: t.me/%s/%s'):format(guname, msg_id)
    end
    if #description > 1 then
      text = text .. _msg('\n• <b>Description</b>: <i>%s</i>'):format(util.escapeHtml(description))
    end

    local owner = db:hgetall('owner' .. chat_id)
    local kmod = db:hgetall('moderators' .. chat_id)
    local mods = {}
    local modlist
    local i = 1

    for id, name in pairs(kmod) do
      if name:match('@') then
        mods[i] = name
        i = i + 1
      end
    end
    for id, name in pairs(owner) do
      if name:match('@') then
        mods[i] = name
        i = i + 1
      end
    end

    local report = util.emptyTable(mods) and '' or text .. '\n\n' .. table.concat(mods, ' ')
    sendText(logchat, 0, report)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)
    local desc = matches[2] or ''
    local text = _msg('Moderators has been notified!')

    if util.isReply(msg) then
      td.getUser(user_id, function(a, d)
        local name = d.first_name_ .. ' [<code>' .. d.id_ .. '</code>]'
        local name = d.username_ and '@' .. d.username_ .. ' AKA ' .. name or name
        report(a.chat_id, a.msg_id, name, a.desc)
      end, {chat_id = chat_id, msg_id = msg.id_, desc = desc})
    else
      text = _msg('Please reply the message and give a description, e.g <code>!report [description]</code>')
    end
    sendText(chat_id, msg.id_, text)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Notifies all moderators of an issue.'),
    usage = {
      user = {
        '<code>!report [description]</code>',
        _msg('Report a replied message and give a description.'),
        '',
      },
    },
    patterns = {
      _config.cmd..'(report)$',
      _config.cmd..'(report) (.+)',
    },
    run = run
  }

end
