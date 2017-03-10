do

  local function getRss(url, prot)
    local res, code = nil, 0

    if prot == 'http' then
      res, code = http.request(url)
    elseif prot == 'https' then
      res, code = https.request(url)
    end
    if code ~= 200 then
      return nil, _msg('There was an error whilst connecting to %s'):format(url)
    end

    local parsed = feedparser.parse(res)

    if parsed == nil then
      return nil, _msg('There was an error retrieving a valid RSS feed from that url. Please, make sure you typed it correctly, and try again.')
    end
    return parsed, nil
  end

  local function getNewEntries(last, nentries)
    local entries = {}

    for k, v in pairs(nentries) do
      if v.id == last then
        return entries
      else
        table.insert(entries, v)
      end
    end
    return entries
  end

  local function printSubs(id)
    local subs = db:hgetall('rss' .. id)
    local subscribed = {}
    local i = 1

    for k, v in pairs(subs) do
      subscribed[i] = k
      i = i + 1
    end

    if not util.emptyTable(subscribed) then
      local subscriber = id:match('-') and db:get('title' .. id) .. ' is' or 'You are'
      local title = _msg('%s subscribed to:\n• '):format(subscriber)
      return title, subscribed
    else
      return _msg('You are not subscribed to any RSS feeds!'), {}
    end
  end

  local function subscribe(id, baseurl)
    local protocol = baseurl:match('https://') and 'https' or 'http'
    local rhash = 'rss' .. id

    if db:hlen(rhash) >= 3 then
      return sendText(id, 0, _msg('You cannot subscribe to more than 3 RSS feeds!'))
    end
    if db:hexists(rhash, baseurl) then
      return sendText(id, 0, _msg('You are already subscribed to %s'):format(baseurl))
    end

    local parsed, err = getRss(baseurl, protocol)

    if err ~= nil then
      return err
    end

    local last_entry = ''

    if #parsed.entries > 0 then
      last_entry = parsed.entries[1].id
    end

    local name = parsed.feed.title

    db:hset(rhash, baseurl, last_entry)
    return sendText(id, 0, _msg('You had been subscribed to %s'):format(name))
  end

  local function unsubscribe(id, n)
    n = tonumber(n)
    local rhash = 'rss' .. id
    local subscribed = db:hlen(rhash)

    if n < 1 or n > subscribed then
      return sendText(id, 0, _msg('Please enter a valid subscription ID.'))
    end

    local _, sub = printSubs(id)

    db:hdel(rhash, sub[n])

    if subscribed < 1 then -- no one subscribed, remove it
      db:del(rhash)
    end

    return sendText(id, 0, _msg('You will no longer receive updates from %s.'):format(sub[n]))
  end

--------------------------------------------------------------------------------

  local last_sync

  local function cron(now)
    last_sync = (last_sync or 0) + 1

    if now then last_sync = 15 end

    -- Sync every 15 minutes?
    if last_sync < 15 then return end

    local keys = db:keys('rss*')

    for i = 1, #keys do
      local subscribers = db:hgetall(keys[i])
      local base = keys[i]:sub(4, -1)
      local feeds = {}

      for url, latest in pairs(subscribers) do
        local protocol = url:match('https://') and 'https' or 'http'
        local parsed, err = getRss(url, protocol)

        if err ~= nil then
          return
        end

        local newentr = getNewEntries(latest, parsed.entries)
        local latest_entry = newentr[1] and newentr[1].id or latest
        local n = 1

        for k2, v2 in pairs(newentr) do
          local title = v2.title or 'No title'
          local link = v2.link or v2.id or 'No Link'
          feeds[n] = '• <a href="' .. link .. '">' .. util.escapeHtml(title) .. '</a>'
          n = n + 1
        end
        db:hset('rss' .. base, url, latest_entry)
      end
      if not util.emptyTable(feeds) then
        local text = table.concat(feeds, '\n')
        local msg = {chat_id_ = base, id_ = 0}
        util.apiSendMessage(msg, text, 'HTML', 1)
      end
      last_sync = 0
    end
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)
    local id = util.isChatMsg(msg) and chat_id or user_id

    -- Limit users to owners so this plugin won't be a resource hog to the bot
    if getRank(user_id, chat_id) < 3 then return nil end

    if matches[1] == 'rss'then
      local title, subscribed = printSubs(id)
      return title .. table.concat(subscribed, '\n• ')
    end
    if matches[1] == 'sync' then
      if not _config.sudoers[user_id] then
        return sendText(chat_id, msg.id_, 'Only sudo users can sync the RSS.')
      end
      cron(true)
    end
    if matches[1] == 'subscribe' or matches[1] == 'sub' then
      return subscribe(id, matches[2])
    end
    if matches[1] == 'unsubscribe' or matches[1] == 'uns' or matches[1] == 'del' then
      return unsubscribe(id, matches[2])
    end
  end

--------------------------------------------------------------------------------

  return {
    description = 'Manage User/Chat RSS subscriptions. If you are in a chat group, the RSS subscriptions will be of that chat. If you are in an one-to-one talk with the bot, the RSS subscriptions will be yours.',
    usage = {
      owner = {
        --'<code>!rss</code>',
        --'Get your rss (or chat rss) subscriptions',
        --'',
        --'<code>!rss subscribe [url]</code>',
        --'<code>!rss sub [url]</code>',
        --'Subscribe to that url',
        --'',
        --'<code>!rss unsubscribe [id]</code>',
        --'<code>!rss uns [id]</code>',
        --'<code>!rss del [id]</code>',
        --'Unsubscribe of that id',
        --'',
        --'<code>!rss sync</code>',
        --'Download now the updates and send it. Only sudo users can use this option.'
        --'',
      },
      user = {
        'https://telegra.ph/RSS-03-10',
      },
    },
    patterns = {
      _config.cmd .. '(rss)$',
      _config.cmd .. 'rss (subscribe) (https?://[%w-_%.%?%.:/%+=&]+)$',
      _config.cmd .. 'rss (sub) (https?://[%w-_%.%?%.:/%+=&]+)$',
      _config.cmd .. 'rss (unsubscribe) (%d+)$',
      _config.cmd .. 'rss (uns) (%d+)$',
      _config.cmd .. 'rss (del) (%d+)$',
      _config.cmd .. 'rss (sync)$'
    },
    run = run,
    cron = cron
  }

end

