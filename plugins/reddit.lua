do

  local function run(msg, matches)
    local thread_limit = util.isChatMsg(msg) and 4 or 8
    local is_nsfw = false
    local url = 'https://www.reddit.com/'

    if matches[1] == 'nsfw' then
      is_nsfw = true
    end

    if #matches == 1 then
      url = url .. '.json?limit=' .. thread_limit
    else
      if matches[2]:match('^r/') then
        url = url .. matches[2] .. '/.json?limit=' .. thread_limit
      else
        url = url .. 'search.json?q=' .. matches[2] .. '&limit=' .. thread_limit
      end
    end

    -- Do the request
    local res, code = https.request(url)

    if code ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg("There doesn't seem to be anything..."))
    end

    local jdat = json.decode(res)
    local jdata_child = jdat.data.children

    if #jdata_child == 0 then
      return nil
    else
      local threadit = {}
      local long_url = ''

      for k=1, #jdata_child do
        local redd = jdata_child[k].data

        if not redd.is_self then
          local link = URL.parse(redd.url)
          long_url = '\nLink: <a href="' .. redd.url .. '">' .. link.scheme .. '://' .. link.host .. '</a>'
        end

        local title = util.unescapeHtml(redd.title)

        if #title > 256 then
          title = title:sub(1, 253)
          title = util.trim(title) .. '...'
        end

        if redd.over_18 and not is_nsfw then
          threadit[k] = ''
        elseif redd.over_18 and is_nsfw then
          threadit[k] = '<b>' .. k .. '. NSFW</b> ' .. '<a href="redd.it/' .. redd.id .. '">' .. title .. '</a>' .. long_url
        else
          threadit[k] = '<b>' .. k .. '. </b>' .. '<a href="redd.it/' .. redd.id .. '">' .. title .. '</a>' .. long_url
        end
      end

      local threadit = table.concat(threadit, '\n')
      local subreddit = matches[2] or 'redd.it'
      local subreddit = '<b>' .. subreddit .. '</b>\n' .. threadit

      if not threadit:match('%w+') then
        sendText(msg.chat_id_, msg.id_, _msg('You must be 18+ to view this community.'))
      else
        util.apiSendMessage(msg, subreddit, 'HTML', true)
      end
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns the top posts or results for a given subreddit or query.\n'
                  .. 'If no argument is given, returns the top posts from r/all.\n'
                  .. 'Querying specific subreddits is not supported.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/83'
        --'<code>!reddit</code>',
        --_msg('Reddit frontpage.'),
        --'',
        --'<code>!reddit r/[query]</code>',
        --'<code>!r r/[query]</code>',
        --_msg('Subreddit'),
        --_msg('<b>Example</b>') .. ': <code>!r r/linux</code>',
        --'',
        --'<code>!redditnsfw [query]</code>',
        --'<code>!rnsfw [query]</code>',
        --_msg('Subreddit (include NSFW).'),
        --_msg('<b>Example</b>') .. ': <code>!rnsfw r/juicyasians</code>',
        --'',
        --'<code>!reddit [query]</code>',
        --'<code>!r [query]</code>',
        --_msg('Search subreddit.'),
        --_msg('<b>Example</b>') .. ': <code>!r telegram bot</code>',
        --'',
        --'<code>!redditnsfw [query]</code>',
        --'<code>!rnsfw [query]</code>',
        --_msg('Search subreddit (include NSFW).'),
        --_msg('<b>Example</b>') .. ': <code>!rnsfw maria ozawa</code>',
      },
    },
    patterns = {
      _config.cmd .. '(reddit)$',
      _config.cmd .. '(r) (.*)$',
      _config.cmd .. '(reddit) (.*)$',
      _config.cmd .. 'r(nsfw) (.*)$',
      _config.cmd .. 'reddit(nsfw) (.*)$',
    },
    run = run
  }

end
