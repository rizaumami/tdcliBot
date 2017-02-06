do

  local function run(msg, matches)
    if matches[1] then
      local str = matches[1]
      local bit = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
      local b64 = ((str:gsub(
        '.',
        function(x)
          local r, bit = '', x:byte()
          for integer = 8, 1, -1 do
            r = r .. (bit % 2^integer - bit % 2^(integer - 1) > 0 and '1' or '0')
          end
          return r
        end
      ) .. '0000'):gsub(
        '%d%d%d?%d?%d?%d?',
        function(x)
          if (#x < 6) then
            return
          end
          local c = 0
          for integer = 1, 6 do
            c = c + (x:sub(integer, integer) == '1' and 2^(6 - integer) or 0)
          end
          return bit:sub(c + 1, c + 1)
        end
      ) .. ({ '', '==', '=' })[#str % 3 + 1])

      sendText(msg.chat_id_, msg.id_, '<code>' .. util.escapeHtml(b64) .. '</code>')
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Converts the given string to base64.'),
    usage = {
      user = {
        '<code>!base64 [string]</code>',
        '<code>!b64 [string]</code>',
        _msg('Converts the given <code>string</code> to base64.')
      },
    },
    patterns = {
      _config.cmd .. 'base64 (.*)$',
      _config.cmd .. 'b64 (.*)$'
    },
    run = run
  }

end

