do

  local function run(msg, matches)
    if matches[2] then
      if matches[2]:match('%a%a') then
        local lang = matches[2]:lower()
        _config.language.default = lang
        saveConfig()
        local text = _msg('Bot language is set to <b>%s</b>'):format(matches[2])
        sendText(msg.chat_id_, msg.id_, text)
      else
        sendText(msg.chat_id_, msg.id_, _msg('Language must be in form of two letter ISO 639-1 language code.'))
      end
    elseif matches[1] == 'listlang' or matches[1] == 'setlang' then
      local l = {}
      local lt = _config.language.available_languages
  
      for i = 1, #lt do
        if _config.language.default == lt[i] then
          l[i] = '• ' .. lt[i] .. '  (default)'
        else
          l[i] = '• ' .. lt[i]
        end
      end

      local title = _msg("<b>List of available languages</b>:\n")
      local langs = table.concat(l, '\n')
        
      sendText(msg.chat_id_, msg.id_, title .. langs)
    end
  end

  return {
    description = _msg('Set bots language.'),
    usage = {
      sudo = {
        '<code>!listlang</code>',
        '<code>!setlang</code>',
        _msg('List available languages.'),
        '',
        '<code>!setlang [language_code]</code>',
        _msg('Set bots language.\nLanguage ID is in a form of ISO 639-1 language code.'),
        _msg('<b>Example</b>') .. ': <code>!setlang id</code> will set bots language to Bahasa Indonesia.',
        '',
      },
    },
    patterns = {
      _config.cmd .. '(listlang)$',
      _config.cmd .. '(setlang)$',
      _config.cmd .. '(setlang) (%a%a)$',
    },
    run = run,
    privilege = 5,
  }

end
