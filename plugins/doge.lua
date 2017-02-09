do

  local function run(msg, matches)
    local base = 'http://dogr.io/'
    local dogetext = URL.escape(matches[1])
    local dogetext = string.gsub(dogetext, '%%2f', '/')
    local url = base .. dogetext .. '.png?split=false&.png'
    local urlm = 'https?://[%%%w-_%.%?%.:/%+=&]+'

    if string.match(url, urlm) == url then
      util.apiSendPhoto(msg, url)
    else
      local text = _msg("Can't build a good URL with parameter %s"):format(matches[1])
      sendText(msg.chat_id_, msg.id_, text)
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Doge-ifies the given text.\nSentences are separated using slashes.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/39'
        --'<code>!dogify (your/words/with/slashes)</code>',
        --'<code>!doge (your/words/with/slashes)</code>',
        --_msg('Create a doge with the image and words.'),
        --_msg('<b>Example</b>') .. ': <code>!doge wow/merbot/soo/cool</code>',
      },
    },
    patterns = {
      _config.cmd .. 'dogify (.+)$',
      _config.cmd .. 'doge (.+)$',
    },
    run = run
  }

end
