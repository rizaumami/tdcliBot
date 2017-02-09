do

  local function run(msg, matches)
    local input = tostring(matches[1])
    local res = {}
    local seq = 0
    local val = nil
    for i = 1, #input do
      local char = input:byte(i)
      if seq == 0 then
        table.insert(res, val)
        seq = char < 0x80 and 1 or char < 0xE0 and 2 or char < 0xF0 and 3 or char < 0xF8 and 4 or error('invalid UTF-8 character sequence')
        val = bit32.band(char, 2 ^ (8 - seq) - 1)
      else
        val = bit32.bor(
          bit32.lshift(val, 6),
          bit32.band(char, 0x3F)
        )
      end
      seq = seq - 1
    end
    table.insert(res, val)

    local unicode = '<code>' .. json.encode(res) .. '</code>'

    sendText(msg.chat_id_, msg.id_, unicode)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns the given text as a json-encoded table of Unicode (UTF-32) values.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/92'
        --'<code>!unicode [text]</code>',
        --_msg('Returns the given <code>text</code> as a json-encoded table of Unicode (UTF-32) values.')
      },
    },
    patterns = {
      _config.cmd .. 'unicode (.*)$'
    },
    run = run
  }

end
