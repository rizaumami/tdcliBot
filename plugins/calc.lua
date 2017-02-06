do

  local function run(msg, matches)
    local result = http.request('http://api.mathjs.org/v1/?expr=' .. URL.escape(matches[1]))

    if not result then
      result = _msg('Unexpected error\nIs api.mathjs.org up?')
    end

    sendText(msg.chat_id_, msg.id_, '<b>' .. result .. '</b>')
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns solutions to mathematical expressions and conversions between common units.'
                  .. 'Results provided by mathjs.org.'),
    usage = {
      user = {
        '<code>!calc [expression]</code>',
        '<code>!calculator [expression]</code>',
        _msg('Evaluates the expression and sends the result.'),
      },
    },
    patterns = {
      _config.cmd .. 'calc (.*)$',
      _config.cmd .. 'calculator (.*)'
    },
    run = run
  }

end
