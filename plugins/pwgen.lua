-- https://rosettacode.org/mw/index.php?title=Password_generator&action=edit&section=11

do

  local function randPW (length, symbols)
    local index, pw, rnd = 0, ''
    local chars = {
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      'abcdefghijklmnopqrstuvwxyz',
      '0123456789'
    }

    if symbols then
      local n = #chars + 1
      chars[n] = "!\"#$%&'()*+,-./:;<=>?@[]^_{|}~"
    end
    repeat
      index = index + 1
      rnd = math.random(chars[index]:len())
      if math.random(2) == 1 then
        pw = pw .. chars[index]:sub(rnd, rnd)
      else
        pw = chars[index]:sub(rnd, rnd) .. pw
      end
      index = index % #chars
    until pw:len() >= tonumber(length)
    return pw
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local randpass

    if #matches == 3 then
      randpass = randPW(matches[2], matches[3])
    elseif #matches == 2 then
      randpass = randPW(matches[2])
    else
      randpass = randPW(8)
    end
    sendText(msg.chat_id_, msg.id_, '<code>' .. randpass .. '</code>')
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Generate random passwords.'),
    usage = {
      user = {
        'https://telegra.ph/pwgen-03-10',
        --'<code>!pwgen</code>',
        --_msg('Generate 8 digit random passwords.'),
        --'',
        --'<code>!pwgen [pw_length]</code>',
        --_msg('Generate <code>pw_length</code> digit random passwords.'),
        --'',
        --'<code>!pwgen [pw_length] symbols</code>',
        --_msg('Include at least one special symbol in the password.'),
        --'',
      },
    },
    patterns = {
      _config.cmd .. '(pwgen)$',
      _config.cmd .. '(pwgen) (%d+)$',
      _config.cmd .. '(pwgen) (%d+) (symbols?)$',
    },
    run = run
  }

end


