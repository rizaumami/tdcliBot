do

  -- Get commands for that plugin
  local function pluginHelp(name, number, requester)
    local plugin
    local text = ''
    local usage_for

    if number then
      local i = 0

      for name in util.pairsByKeys(plugins) do
        i = i + 1
        if i == tonumber(number) then
          plugin = plugins[name]
          text = '<b>' .. name .. '</b>\n'
        end
      end
    else
      plugin = plugins[name]
      if not plugin then return nil end
    end

    local text = text .. plugin.description .. '\n\n'
    local usage_for

    for ku, usage in pairs(plugin.usage) do
      if ku == 'user' then -- usage for user
        usage_for = plugin.usage.user
      elseif (ku == 'moderator') and requester > 1 then
        usage_for = plugin.usage.moderator
      elseif (ku == 'owner') and requester > 2 then
        usage_for = plugin.usage.owner
      elseif (ku == 'admin') and requester > 3 then
        usage_for = plugin.usage.admin
      elseif (ku == 'sudo') and requester > 4 then
        usage_for = plugin.usage.sudo
      end

      if not usage_for then
        text = _msg('The plugins is not for your privilege.')
      else
        for u = 1, #usage_for do
          text = text .. usage_for[u] .. '\n'
        end
      end
    end

    return text
  end

  -- !help command
  local function telegramHelp(msg)
    local i = 0
    local text = '<b>Plugins</b>\n\n'
    -- Plugins names
    for name in util.pairsByKeys(plugins) do
      i = i + 1
      text = text .. '<b>' .. i .. '</b>. ' .. name .. '\n'
    end

    local footer = _msg('\n' .. 'There are <b>%s</b> plugins help available.\n'
           .. '<b>-</b> <code>!help [plugin name]</code> for more info.\n'
           .. '<b>-</b> <code>!help [plugin number]</code> for more info.\n'
           .. '<b>-</b> <code>!help all</code> to show all info.'):format(i)

    sendText(msg.chat_id_, msg.id_, text .. footer)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)
    local text

    if _config.sudoers[user_id] then
      requester = 5
    elseif _config.administrators[user_id] then
      requester = 4
    elseif db:hexists('owner' .. chat_id, user_id) then
      requester = 3
    elseif db:hexists('moderators' .. chat_id, user_id) then
      requester = 2
    else
      requester = 1
    end

    if matches[2] then
      if matches[2] == 'all' then
        return sendText(chat_id, msg.id_, _msg('Please read @tdclibotmanual'))
      elseif matches[2]:match('^%d+$') then
          text = pluginHelp(nil, matches[2], requester)
      else
        text = pluginHelp(matches[2], nil, requester)
      end
    else
      return telegramHelp(msg)
    end

    if not text then
      text =  _msg('No help entry for "<b>%s</b>".\n'
              .. 'Please visit @tdclibotmanual for the complete list.'):format(matches[2])
    end
    sendText(chat_id, msg.id_, text)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Get info from other plugins.'),
    usage = {
      user = {
        _msg('<code>!help</code>',
        'Show list of plugins.'),
        '',
        '<code>!help all</code>',
        _msg('Show all commands for every plugin.'),
        '',
        '<code>!help [plugin_name]</code>',
        _msg('Commands for that plugin.'),
        '',
        '<code>!help [number]</code>',
        _msg('Commands for that plugin. Type !help to get the plugin number.')
      },
    },
    patterns = {
      _config.cmd .. '(help)$',
      _config.cmd .. '(help) (%g+)$',
    },
    run = run
  }

end
