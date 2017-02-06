do

  local function run(msg, matches)
    if not matches[1]:match('^%d+$') then
      sendText(msg.chat_id_, msg.id_, _msg('You must enter a numerical value!'))
      return
    end

    local input = matches[1]
    local result = ''
    local split, integer, fraction

    repeat
      split = tonumber(input) / 2
      integer, fraction = math.modf(split)
      input = integer
      result = math.ceil(fraction) .. result
    until input == 0

    local str = result:format('s')
    local zero = 16 - str:len()
    local text = string.rep('0', zero) .. str

    sendText(msg.chat_id_, msg.id_, '<code>' .. text .. '</code>')
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Converts the given number to binary.'),
    usage = {
      user = {
        '<code>!binary [number]</code>',
        _msg('Converts the given <code>number</code> to binary.')
      },
    },
    patterns = {
      _config.cmd .. 'binary (%w+)$'
    },
    run = run
  }

end
