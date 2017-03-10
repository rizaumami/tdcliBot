do

  local function run(msg, matches)
    local omdbapi = 'http://www.omdbapi.com/?plot=full&r=json'
    local movietitle = matches[1]
    local chat_id = msg.chat_id_

    if matches[1]:match(' %d%d%d%d$') then
      local movieyear = matches[1]:match('%d%d%d%d$')
      movietitle = matches[1]:match('^.+ ')
      omdbapi = omdbapi .. '&y=' .. movieyear
    end

    local success, code = http.request(omdbapi .. '&t=' .. URL.escape(movietitle))

    if not success then
      return sendText(chat_id, msg.id_, _msg('Connection error'))
    end

    local jomdb = json.decode(success)

    if not jomdb then
      return sendText(chat_id, msg.id_, '<b>' .. json.decode(code) .. '</b>')
    elseif jomdb.Response == 'False' then
      return sendText(chat_id, msg.id_, '<b>' .. jomdb.Error .. '</b>')
    end

    local omdb = _msg('<b>%s</b>\n\n'
                      .. '<b>Year</b><a href="%s">:</a> %s\n'
                      .. '<b>Rated</b>: %s\n'
                      .. '<b>Runtime</b>: %s\n'
                      .. '<b>Genre</b>: %s\n'
                      .. '<b>Director</b>: %s\n'
                      .. '<b>Writer</b>: %s\n'
                      .. '<b>Actors</b>: %s\n'
                      .. '<b>Country</b>: %s\n'
                      .. '<b>Awards</b>: %s\n'
                      .. '<b>Plot</b>: %s\n\n'
                      .. '<a href="http://imdb.com/title/%s">IMDB</a>:\n'
                      .. '<b>Metascore</b>: %s\n'
                      .. '<b>Rating</b>: %s\n'
                      .. '<b>Votes</b>: %s\n'):format(jomdb.Title,
                                                      jomdb.Poster,
                                                      jomdb.Year,
                                                      jomdb.Rated,
                                                      jomdb.Runtime,
                                                      jomdb.Genre,
                                                      jomdb.Director,
                                                      jomdb.Writer,
                                                      jomdb.Actors,
                                                      jomdb.Country,
                                                      jomdb.Awards,
                                                      jomdb.Plot,
                                                      jomdb.imdbID,
                                                      jomdb.Metascore,
                                                      jomdb.imdbRating,
                                                      jomdb.imdbVotes
    )
    util.apiSendMessage(msg, omdb, 'HTML', false)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('The Open Movie Database plugin for Telegram.'),
    usage = {
      user = {
        'https://telegra.ph/IMDb-03-10',
        --'<code>!imdb [movie]</code>',
        --'<code>!omdb [movie]</code>',
        --_msg('Returns IMDb entry for <code>[movie]</code>'),
        --_msg('<b>Example</b>') .. ': <code>!imdb the matrix</code>',
        --'',
        --'<code>!imdb [movie] [year]</code>',
        --'<code>!omdb [movie] [year]</code>',
        --_msg('Returns IMDb entry for <code>[movie]</code> that was released in <code>[year]</code>'),
        --_msg('<b>Example</b>') .. ': <code>!imdb the matrix 2003</code>',
      },
    },
    patterns = {
      _config.cmd .. '[io]mdb (.+)$',
    },
    run = run
  }

end
