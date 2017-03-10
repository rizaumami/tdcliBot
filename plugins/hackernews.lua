do

  local function run(msg, matches)
    local feed_url = 'https://news.ycombinator.com/rss'
    local res, code = https.request(feed_url)
    local limit = util.isChatMsg(msg) and 4 or 8

    if code ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('Connection error'))
    end

    local parsed = feedparser.parse(res, feed_url)
    local results = {}

    for i = 1, limit do
      local entry = parsed.entries[i]
      local url = entry.summary:match('"(.+)"')
      results[i] = string.format(
        '• <code>[</code><a href="%s">%s</a><code>]</code> <a href="%s">%s</a>',
        util.escapeHtml(url),
        url:match('%d+$'),
        -- We don't want the title to be linked if it's a "self" post.
        -- Pass an empty string for the URL if the link is the comment page.
        url == entry.link and '' or util.escapeHtml(entry.link),
        util.escapeHtml(entry.title)
      )
    end
    local output = '<b>Top Posts from Hacker News:</b>\n' .. table.concat(results, '\n')
    util.apiSendMessage(msg, output, 'HTML', true)
  end

--------------------------------------------------------------------------------

  return {
  description = _msg('Returns a list of top stories from Hacker News.'),
  usage = {
    user = {
      'https://telegra.ph/Hacker-News-02-09',
      --'<code>!hn</code>',
      --'<code>!hackernews</code>',
      --_msg('Returns a list of top stories from Hacker News.'),
    },
  },
  patterns = {
    _config.cmd .. 'hn$',
    _config.cmd .. 'hackernews$',
  },
  run = run
  }

end
