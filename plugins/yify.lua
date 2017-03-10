do

  local function run(msg, matches)
    local query = matches[1]
    local url = 'https://yts.ag/api/v2/list_movies.json?limit=1&query_term=' .. URL.escape(query)
    local resp = {}
    local b,c = https.request {
      url = url,
      protocol = 'tlsv1',
      sink = ltn12.sink.table(resp)
    }
    local resp = table.concat(resp)
    local jresult = json.decode(resp)

    if not jresult.data.movies then
      sendText(msg.chat_id_, msg.id_, _msg('No torrent results for: %s'):format(query))
    else
      local yify = jresult.data.movies[1]
      local yts = yify.torrents
      local yifylist = {}

      for i=1, #yts do
        local torrent = yts[i]
        yifylist[i] = string.format(
          '<b>%s</b>: <a href="%s">.torrent</a>\nSeeds: <code>%s</code> | Peers: <code>%s</code> | Size: <code>%s</code>',
          torrent.quality,
          torrent.url,
          torrent.seeds,
          torrent.peers,
          torrent.size
        )
      end

      local output = string.format(
        '<b>%s</b>\n\n<b>%s</b>/10 <a href="%s">|</a> %s min\n\n%s\n\n%s\n<a href="%s">More on yts.ag...</a>',
        yify.title_long,
        yify.rating,
        yify.large_cover_image,
        yify.runtime,
        table.concat(yifylist, '\n\n'),
        yify.synopsis:sub(1, 2000),
        yify.url
      )

      util.apiSendMessage(msg, output, 'HTML')
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Searches Yify torrents for the given query.'),
    usage = {
      user = {
        'https://telegra.ph/Yify-02-08',
        --'<code>!yify [search term]</code>',
        --'<code>!yts [search term]</code>',
        --_msg('Search YTS YIFY movie torrents from yts.ag'),
        --_msg('<b>Example</b>') .. ': <code>!yts ex machina</code>',
      },
    },
    patterns = {
      _config.cmd .. 'yify (.+)$',
      _config.cmd .. 'yts (.+)$'
    },
    run = run,
  }

end
