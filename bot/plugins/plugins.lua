do

  local function pluginsTable(plugins_type)
    local plugins_table = _config.plugins.usr
    if plugins_type == 'sys' then
      plugins_table = _config.plugins.sys
    end
    return plugins_table
  end

  -- Returns the key (index) in the config.plugins table
  local function pluginsEnabled(name, plugins_type)
    local ptbl = pluginsTable(plugins_type)

    for i = 1, #ptbl do
      if name == ptbl[i] then
        return i
      end
    end

    return false
  end

  -- Returns at table of lua files inside plugins
  local function pluginsNames(path)
    local files = {}
    local plugin = util.scanDir(path)

    for f = 1, #plugin do
      -- Ends with .lua
      if (plugin[f]:match(".lua$")) then
        files[f] = plugin[f]
      end
    end
    return files
  end

  -- Returns true if file exists in plugins folder
  local function pluginExists(name, plugins_dir)
    local plugin_names = pluginsNames(plugins_dir)
    for n = 1, #plugin_names do
      if name .. '.lua' == plugin_names[n] then
        return true
      end
    end
    return false
  end

  local function listPlugins(msg, only_enabled, plugins_type)
    local text = ''
    local psum = 0
    local plug_name = pluginsNames(plugins_dir)

    for l = 1, #plug_name do
      local pname = plug_name[l]

      --  ✅ enabled, ❌ disabled
      local status = '❌'
      local ptt = pluginsTable(plugins_type)
      psum = psum + 1
      pact = 0
      -- Check if is enabled
      for e = 1, #ptt do
        if pname == ptt[e] .. '.lua' then
          status = '✅'
        end
        pact = pact + 1
      end
      if not only_enabled or status == '✅' then
        -- get the name
        pname = pname:match('(.*)%.lua')
        text = text .. status .. '  ' .. pname .. '\n'
      end
    end

    local footer = _msg('\n<b>%s plugins installed</b>\n'
        .. '✅  %s enabled.\n❌  %s disabled.'):format(psum, pact, psum-pact)

    sendText(msg.chat_id_, msg.id_, text .. footer)
  end

  local function reloadPlugins(msg, only_enabled, plugins_type)
    plugins = {}
    loadPlugins()
    return listPlugins(msg, true, plugins_type)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local plugin = matches[2]

    if msg.content_.text_:match('sysplug') then
      plugins_type = 'sys'
      plugins_dir = 'bot/plugins/'
    else
      plugins_type = 'usr'
      plugins_dir = 'plugins/'
    end

    if util.isMod(user_id, chat_id) then
      -- Show the available plugins
      if matches[1] == 'plugins' then
        return listPlugins(msg, false, 'user')
      end

      -- Re-enable a plugin for this chat
      if matches[3] == 'chat' then
        if matches[1] == 'enable' then
          print('enable ' .. plugin .. ' on this chat')
          if not _config.plugins.disabled_on_chat then
            return sendText(chat_id, msg.id_, _msg("There aren't any disabled plugins"))
          end

          if not _config.plugins.disabled_on_chat[chat_id] then
            return sendText(chat_id, msg.id_, _msg("There aren't any disabled plugins for this chat"))
          end

          if not _config.plugins.disabled_on_chat[chat_id][plugin] then
            return sendText(chat_id, msg.id_, _msg('This plugin is not disabled'))
          end

          _config.plugins.disabled_on_chat[chat_id][plugin] = false
          saveConfig()
          local text = _msg('Plugin %s is enabled again'):format(plugin)
          return sendText(chat_id, msg.id_, text)
        end

        -- Disable a plugin on a chat
        if matches[1] == 'disable' then
          print('disable ' .. plugin .. ' on this chat')
          if not pluginExists(plugin, plugins_dir) then
            return sendText(chat_id, msg.id_, _msg("Plugin doesn't exists"))
          end

          if not _config.plugins.disabled_on_chat then
            _config.plugins.disabled_on_chat = {}
          end

          if not _config.plugins.disabled_on_chat[chat_id] then
            _config.plugins.disabled_on_chat[chat_id] = {}
          end

          _config.plugins.disabled_on_chat[chat_id][plugin] = true
          saveConfig()
          local text = _msg('Plugin %s disabled on this chat'):format(plugin)
          return sendText(chat_id, msg.id_, text)
        end
      end
    end

    if not _config.sudoers[user_id] then return end

    if matches[1] == 'setkey' then
      if pluginExists(plugin, plugins_dir) then
        _config.key[plugin] = matches[3]
        saveConfig()
        local text = _msg('%s  api key has been saved.'):format(plugin)
        sendText(chat_id, msg.id_, text)
      else
        local missing = _msg( "<b>Failed to set %s key</b>\n"
                              .. "%s.lua doesn't exist."):format(plugin, plugin)
        sendText(chat_id, msg.id_, missing)
      end
    end

    -- Show the available system/admin plugins
    if matches[1] == 'sysplugs' then
      return listPlugins(msg, false, plugins_type)
    end

    -- Enable a plugin
    if not matches[3] then
      if matches[1] == 'enable' then
        print('enable: ' .. plugin)
        print('checking if ' .. plugin .. '.lua exists')

        -- Check if plugin is enabled
        if pluginsEnabled(plugin, plugins_type) then
          local text = _msg('Plugin %s is enabled'):format(plugin)
          return sendText(chat_id, msg.id_, text)
        end

        -- Checks if plugin exists
        if pluginExists(plugin, plugins_dir) then
          -- Check if plugin is need a key
          local plug = loadfile(plugins_dir .. plugin .. '.lua')()

          if plug.need_api_key then
            if not _config.key[plugin] or _config.key[plugin] == '' then
              local missing = _msg('<b>%s.lua is missing its api key</b>\n'
                              .. 'Will not be enabled.\n\n'
                              .. 'Get it from ' .. plug.need_api_key .. ' and set by using these command:\n'
                              .. '<code>!setkey %s [api_key]</code>'):format(plugin, plugin)
              return sendText(chat_id, msg.id_, missing)
            end
          end
          -- Add to the config table
          table.insert(pluginsTable(plugins_type), plugin)
          print(plugin .. ' added to _config table')
          saveConfig()
          -- Reload the plugins
          return reloadPlugins(msg, false, plugins_type)
        else
          local text = _msg('Plugin %s does not exists'):format(plugin)
          return sendText(chat_id, msg.id_, text)
        end
      end

      -- Disable a plugin
      if matches[1] == 'disable' then
        print('disable: ' .. plugin)
        local text

        -- Check if plugins exists
        if not pluginExists(plugin, plugins_dir) then
          text = _msg('Plugin %s does not exists.'):format(plugin)
        end

        local k = pluginsEnabled(plugin, plugins_type)
        -- Check if plugin is enabled
        if not k then
          text = text .. _msg('\nPlugin %s not enabled.'):format(plugin)
        end

        if text then
          sendText(chat_id, msg.id_, text)
        end

        -- Disable and reload
        table.remove(pluginsTable(plugins_type), k)
        saveConfig()
        return reloadPlugins(msg, true, plugins_type)
      end
    end

    -- Reload all the plugins!
    if matches[1] == 'reload' then
      return reloadPlugins(msg, false, plugins_type)
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Plugin to manage other plugins. Enable, disable or reload.'),
    usage = {
      sudo = {
        '<code>!setkey [plugin_name] [key]</code>',
        _msg('Set plugins API key.'),
        '',
        '<code>!plugins enable [plugin]</code>',
        _msg('Enable plugin.'),
        '',
        '<code>!plugins disable [plugin]</code>',
        _msg('Disable plugin.'),
        '',
        '<code>!plugins reload</code>',
        _msg('Reloads all plugins.')
      },
      moderator = {
        '<code>!plugins</code>',
        _msg('List all plugins.'),
        '',
        '<code>!plugins enable [plugin] chat</code>',
        _msg('Re-enable plugin only this chat.'),
        '',
        '<code>!plugins disable [plugin] chat</code>',
        _msg('Disable plugin only this chat.')
      },
    },
    patterns = {
      _config.cmd .. '(plugins)$',
      _config.cmd .. 'plugins? (enable) ([%w_%.%-]+)$',
      _config.cmd .. 'plugins? (disable) ([%w_%.%-]+)$',
      _config.cmd .. 'plugins? (enable) ([%w_%.%-]+) (chat)$',
      _config.cmd .. 'plugins? (disable) ([%w_%.%-]+) (chat)$',
      _config.cmd .. 'plugins? (reload)$',
      _config.cmd .. '(sysplugs)$',
      _config.cmd .. 'sysplugs? (enable) ([%w_%.%-]+)$',
      _config.cmd .. 'sysplugs? (disable) ([%w_%.%-]+)$',
      _config.cmd .. '(setkey) (%g+) (.*)$',
    },
    run = run
  }

end
