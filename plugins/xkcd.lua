do

  local function getLastId(msg)
    local res, code  = https.request('https://xkcd.com/info.0.json')

    if code ~= 200 then
      sendText(msg.chat_id_, msg.id_, _msg('HTTP ERROR'))
    end

    local data = json.decode(res)

    return data.num
  end

  local function getXkcd(msg, id)
    local res,code  = https.request('https://xkcd.com/' .. id .. '/info.0.json')

    if code ~= 200 then
      sendText(msg.chat_id_, msg.id_, _msg('HTTP ERROR'))
    end

    local data = json.decode(res)
    local link_image = data.img

    if link_image:sub(0,2) == '//' then
      link_image = msg.text:sub(3,-1)
    end

    return link_image, data.num, data.title, data.alt
  end

  function getXkcdRandom(msg)
    local last = getLastId(msg)
    local i = math.random(1, last)
    return getXkcd(msg, i)
  end

  function run(msg, matches)
    if matches[1] == 'xkcd' then
      url, num, title, alt = getXkcdRandom(msg)
    else
      url, num, title, alt = getXkcd(msg, matches[1])
    end
    util.apiSendPhoto(msg, url, title .. '\n\n' .. alt)
  end

  return {
    description = _msg('Returns the latest xkcd strip and its alt text. If a number is given, returns that number strip.'),
    usage = {
      user = {
        '<code>!xkcd</code>',
        _msg('Send random xkcd image and title.'),
        '',
        '<code>!xkcd (id)</code>',
        _msg('Send an xkcd image and title.'),
        _msg('<b>Example</b>') .. ': <code>!xkcd 149</code>',
      },
    },
    patterns = {
      _config.cmd .. '(xkcd)$',
      _config.cmd .. 'xkcd (%d+)',
    },
    run = run
  }

end
