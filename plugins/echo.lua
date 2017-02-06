do

  local function run(msg, matches)
    local parse_mode

    if matches[1] == 'html' then
      parse_mode = 'HTML'
    elseif matches[1] == 'md' then
      parse_mode = 'Markdown'
    end

    td.sendText(msg.chat_id_, 0, 0, 1, nil, matches[2], 1, parse_mode)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Repeats a string of text.'),
    usage = {
      user = {
        '<code>!echo [text]</code>',
        _msg('Repeats a string of text.'),
        '',
        '<code>!html [text]</code>',
        _msg('HTML format a string of text.\nNot support link format.'),
        '',
        '<code>!md [text]</code>',
        _msg('Markdown format a string of text.\nNot support link format'),
        '',
      },
    },
    patterns = {
      _config.cmd .. '(echo) (.*)$',
      _config.cmd .. '(html) (.*)$',
      _config.cmd .. '(md) (.*)$',
    },
    run = run,
  }

end
