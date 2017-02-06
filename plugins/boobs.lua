do

  -- Recursive function
  local function getRandomBootts(attempt, bootts)
    attempt = attempt or 0
    attempt = attempt + 1
    local count = bootts == 'butts' and 3 or 10
    local url = string.format('http://api.o%s.ru/noise/1', bootts)
    local res, status = http.request(url)

    if status ~= 200 then return nil end

    local data = json.decode(res)[1]

    -- The OpenBoobs API sometimes returns an empty array
    if not data and attempt < count then
      print('Cannot get that %s, trying another one...'):format(bootts)
      return getRandomBootts(attempt, bootts)
    end
    local output = string.format('http://media.o%s.ru/%s', bootts, data.preview)
    return output
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local url = getRandomBootts(nil, matches[1])

    if url ~= nil then
      sendText(msg.chat_id_, msg.id_, url, 0)
    else
      local text = _msg('Error getting boobs/butts for you, please try again later.')
      sendText(msg.chat_id_, msg.id_, text)
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Gets a random boobs or butts pic'),
    usage = {
      user = {
        '<code>!boobs</code>',
        _msg('Get a boobs NSFW image. 🔞'),
        '',
        '<code>!butts</code>',
        _msg('Get a butts NSFW image. 🔞'),
        '',
      },
    },
    patterns = {
      _config.cmd .. '(boobs)$',
      _config.cmd .. '(butts)$'
    },
    run = run
  }

end
