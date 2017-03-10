--[[
  hexcolor.lua
  Returns an image of the given color code in hexadecimal format.

  If colorhexa.com ever stops working for any reason, it would be simple to
  generate these images on-the-fly with ImageMagick installed, like so:
    os.execute(string.format(
      'convert -size 128x128 xc:#%s /tmp/%s.png',
      hex,
      hex
    ))
  Or alternatively, use a magic table to produce and store them.
    local colors = {}
    setmetatable(colors, { __index = function(tab, key)
      filename = '/tmp/' .. key .. '.png'
      os.execute('convert -size 128x128 xc:#' .. key .. ' ' .. filename)
      tab[key] = filename
      return filename
    end})

  Copyright 2016 topkecleon <drew@otou.to>
  This code is licensed under the GNU AGPLv3. See /LICENSE for details.

  Modified by @si_kabayan for @tdclibot on 20170116.
]]--

do

  local function run(msg, matches)
    if not matches[2] then
      return
    end

    local chat_id, user_id, _, _ = util.extractIds(msg)
    local url = 'http://www.colorhexa.com/%s.png'
    local input = matches[2]:lower()
    input = input:gsub('#', '')

    if not tonumber('0x' .. input) then
      return sendText(chat_id, msg.id_, _msg('Invalid number.'))
    end

    local hex
    if #input == 1 then
      hex = input .. input .. input .. input .. input .. input
    elseif #input == 2 then
      hex = input .. input .. input
    elseif #input == 3 then
      hex = ''
      for s in input:gmatch('.') do
        hex = hex .. s .. s
      end
    elseif #input == 6 then
      hex = input
    else
      return sendText(chat_id, msg.id_, _msg('Invalid length.'))
    end

    sendText(chat_id, msg.id_, url:format(hex), 0)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns an image of the given color code. Color codes must be in hexadecimal.\n'
                  .. 'Acceptable code formats:\n'
                  .. '<code>FFFFFF -> FFFFFF\n'
                  .. 'F96  -> FF9966\n'
                  .. 'F5   -> F5F5F5\n'
                  .. 'F    -> FFFFFF</code>\n'
                  .. 'The preceding hash symbol is optional.'),
    usage = {
      user = {
        'https://telegra.ph/Hex-Color-02-08',
        --'<code>!color [ffffff]</code>',
        --'<code>!hexcolor [ff00ff]</code>',
        --_msg('Returns an image of the given color code.'),
      },
    },
    patterns = {
      _config.cmd .. '(color) (%g+)$',
      _config.cmd .. '(hexcolor) (%g+)$',
    },
    run = run
  }

end
