do

  local function run(msg, matches)
    local dildate = matches[2] or os.date('%F')

    if not dildate:match('^%d%d%d%d%-%d%d%-%d%d$') then
      dildate = os.date('%F')
    end

    local url = 'http://dilbert.com/strip/' .. URL.escape(dildate)
    local str, res = http.request(url)

    if res ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('Connection error'))
    end

    local strip_title = str:match('<meta property="article:publish_date" content="(.-)"/>')
    local strip_url = str:match('<meta property="og:image" content="(.-)"/>')

    util.apiSendPhoto(msg, strip_url .. '.gif', strip_title)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns the latest Dilbert strip or that of the provided date.\n'
                  .. 'Dates before the first strip will return the first strip. '
                  .. 'Dates after the last trip will return the last strip.\n'
                  .. 'Source: dilbert.com'),
    usage = {
      user = {
        'https://telegra.ph/Dilbert-02-08',
        --'<code>!dilbert</code>',
        --_msg('Returns todays Dilbert comic'),
        --'',
        --'<code>!dilbert YYYY-MM-DD</code>',
        --_msg('Returns Dilbert comic published on <code>YYYY-MM-DD</code>'),
        --_msg('<b>Example</b>') .. ': <code>!dilbert 2016-08-17</code>',
        --'',
      },
    },
    patterns = {
      _config.cmd .. '(dilbert)$',
      _config.cmd .. '(dilbert) (%g+)$'
    },
    run = run
  }

end
