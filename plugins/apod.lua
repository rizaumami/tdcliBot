do

  local function run(msg, matches)
    local url = 'https://api.nasa.gov/planetary/apod?api_key=' .. _config.key.apod

    if matches[2] then
      if matches[2]:match('%d%d%d%d%-%d%d%-%d%d$') then
        url = url .. '&date=' .. URL.escape(matches[2])
      else
        local text = _msg('*Request must be in following format*:\n`!%s YYYY-MM-DD`'):format(matches[1])
        return sendText(msg.chat_id_, msg.id_, text, 1, 'Markdown')
      end
    end

    local str, res = https.request(url)
    local jstr = json.decode(str)

    if res ~= 200 then
      return sendText(msg.chat_id_, msg.id_, jstr.error.message)
    end

    if jstr.error then
      return sendText(msg.chat_id_, msg.id_, _msg('<b>No results found</b>'))
    end

    local img_url = jstr.hdurl or jstr.url
    local apod = '<b>' .. jstr.title .. '</b>'

    if matches[1] == 'apodtext' then
      apod = apod .. '\n\n' .. jstr.explanation
    end

    if jstr.copyright then
      apod = apod .. _msg('\n\n<i>Copyright') .. ': ' .. jstr.copyright .. '</i>'
    end

    sendText(msg.chat_id_, msg.id_, apod .. '\n\n' .. img_url, 0)
  end

  return {
    description = _msg("Returns the NASA's Astronomy Picture of the Day."),
    usage = {
      sudo = {
        '<code>!setapikey apod [need_api_key]</code>',
        _msg('Set NASA APOD API key.'),
        '',
      },
      user = {
        '<code>!apod</code>',
        _msg('Returns the Astronomy Picture of the Day (APOD).'),
        '',
        '<code>!apod YYYY-MM-DD</code>',
        _msg('Returns the <code>YYYY-MM-DD</code> APOD.'),
        _msg('<b>Example</b>') .. ': <code>!apod 2016-08-17</code>',
        '',
        '<code>!apodtext</code>',
        _msg('Returns the explanation of the APOD.'),
        '',
        '<code>!apodtext YYYY-MM-DD</code>',
        _msg('Returns the explanation of <code>YYYY-MM-DD</code> APOD.'),
        _msg('<b>Example</b>') .. ': <code>!apodtext 2016-08-17</code>',
        '',
      },
    },
    patterns = {
      _config.cmd .. '(apod)$',
      _config.cmd .. '(apodtext)$',
      _config.cmd .. '(apod) (%g+)$',
      _config.cmd .. '(apodtext) (%g+)$',
    },
    run = run,
    need_api_key = 'http://api.nasa.gov'
  }

end
