do

  local function run(msg, matches)
    local lang = _config.language.default
    local query = matches[1]

    if matches[2] then
      lang = matches[1]
      query = matches[2]
    end

    local search_url = 'https://' .. lang .. '.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch='
    local res_url = 'https://' .. lang .. '.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exchars=4000&explaintext=&titles='
    local art_url = 'https://' .. lang .. '.wikipedia.org/wiki/'

    if not query then
      return
    end

    local jstr, code = https.request(search_url .. URL.escape(query))

    if code ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('<b>Connection error</b>'))
    end

    local data = json.decode(jstr)

    if data.query.searchinfo.totalhits == 0 then
      return sendText(msg.chat_id_, msg.id_, _msg('<b>No results found</b>'))
    end

    local title

    for _, v in ipairs(data.query.search) do
      if not v.snippet:match('may refer to:') then
        title = v.title
        break
      end
    end
    if not title then
      return sendText(msg.chat_id_, msg.id_, _msg('No results found'))
    end

    local res_jstr, res_code = https.request(res_url .. URL.escape(title))

    if res_code ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('Connection error'))
    end

    local _, text = next(json.decode(res_jstr).query.pages)

    if not text then
      return sendText(msg.chat_id_, msg.id_, _msg('No results found'))
    end

    text = text.extract
    local l = text:find('\n')

    if l then
      text = text:sub(1, l-1)
    end

    local url = art_url .. URL.escape(title)
    title = title
    local short_title = title:gsub('%(.+%)', '')
    local combined_text, count = text:gsub('^'..short_title, '<b>'..short_title..'</b>')
    local body

    if count == 1 then
      body = combined_text
    else
      body = '<b>' .. title .. '</b>\n' .. text
    end

    sendText(msg.chat_id_, msg.id_, body .. '\n' .. url)
  end

  return {
    description = _msg('Returns an article from Wikipedia.'),
    usage = {
      user = {
        '<code>!w [query]</code>',
        '<code>!wiki [query]</code>',
        '<code>!wikipedia [query]</code>',
        _msg('Returns wikipedia article for <code>query</code>.'),
        '',
        '<code>!w[lang] [query]</code>',
        '<code>!wiki[lang] [query]</code>',
        '<code>!wikipedia[lang] [query]</code>',
        _msg('Returns wikipedia article in <code>[language]</code> for <code>query</code>.\n'
        .. '<b>Example</b>: <code>!wid, !wikiid, !wikipediaid</code> for wikipedia entry in Bahasa Indonesia.')
      },
    },
    patterns = {
      _config.cmd .. 'w(%a%a) (.*)$',
      _config.cmd .. 'w (.*)$',
      _config.cmd .. 'wiki(%a%a) (.*)$',
      _config.cmd .. 'wiki (.*)$',
      _config.cmd .. 'wikipedia(%a%a) (.*)$',
      _config.cmd .. 'wikipedia (.*)$',
    },
    run = run
  }

end
