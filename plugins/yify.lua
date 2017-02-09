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
      sendText(msg.chat_id_, msg.id_, _msg('<b>No torrent results for</b>: ') .. query)
    else
      local yify = jresult.data.movies[1]
      local yts = yify.torrents
      local yifylist = {}

      for i=1, #yts do
        yifylist[i] = '<b>' .. yts[i].quality .. '</b>: <a href="' .. yts[i].url .. '">.torrent</a>\n'
            .. 'Seeds: <code>' .. yts[i].seeds .. '</code> | ' .. 'Peers: <code>' .. yts[i].peers .. '</code> | ' .. 'Size: <code>' .. yts[i].size .. '</code>'
      end

      local torrlist = table.concat(yifylist, '\n\n')
      local title = '<b>' .. yify.title_long .. '</b>'
      local output = title .. '\n\n'
          .. '<b>' .. yify.rating .. '</b>/10 <a href="' .. yify.large_cover_image .. '">|</a> ' .. yify.runtime .. ' min\n\n'
          .. torrlist .. '\n\n' .. yify.synopsis:sub(1, 2000) .. '\n<a href="' .. yify.url .. '"> More on yts.ag ...</a>'

      util.apiSendMessage(msg, output, 'HTML')
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Searches Yify torrents for the given query.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/107'
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
