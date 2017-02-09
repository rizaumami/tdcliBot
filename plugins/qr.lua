do

  local function run(msg, matches)
    if matches[1] then
      local url = 'http://chart.apis.google.com/chart?cht=qr&chs=500x500&chl=' .. URL.escape(matches[1]) .. '&chld=H|0.png'

      td.sendChatAction(msg.chat_id_, 'UploadPhoto')
      util.apiSendPhoto(msg, url)
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Converts the given string to a QR code.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/77'
        --'<code>!qr [string]</code>',
        --_msg('Converts the given <code>string</code> to a QR code.')
      },
    },
    patterns = {
      _config.cmd .. 'qr (.*)$'
    },
    run = run
  }

end
