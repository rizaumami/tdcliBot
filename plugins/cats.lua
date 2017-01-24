do

  function run(msg, matches)
    local filetype = '&type=jpg'

    if (matches[1] == 'gif') then
      filetype = '&type=gif'
    end

    local url = 'https://thecatapi.com/api/images/get?format=html' .. filetype .. '&need_api_key=' .. _config.key.cats
    local str, res = https.request(url)

    if res ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('Connection error'))
    end

    local cat = str:match('<img src="(.-)">')

    if (matches[1] == 'gif') then
      util.apiSendDocument(msg, cat)
    else
      util.apiSendPhoto(msg, cat)
    end
  end

  return {
    description = _msg('A random picture of a cat!'),
    usage = {
      user = {
        '<code>!cat</code>',
        '<code>!cats</code>',
        _msg('Returns a picture of cat!'),
        '',
        '<code>!cat gif</code>',
        '<code>!cats gif</code>',
        _msg('Returns an animated picture of cat!'),
      },
    },
    patterns = {
      _config.cmd .. 'cats?$',
      _config.cmd .. 'cats? (gif)$',
    },
    run = run,
    need_api_key = 'http://thecatapi.com/docs.html'
  }

end
