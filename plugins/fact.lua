do

  local function run(msg, matches)
    local jstr, res = http.request('http://mentalfloss.com/api/1.0/views/amazing_facts.json?limit=5000')

    if res ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('Connection error'))
    end

    local jdat = json.decode(jstr)
    local result = jdat[math.random(#jdat)].nid:gsub('&lt;', '<'):gsub('<p>', ''):gsub('</p>', '')

    sendText(msg.chat_id_, msg.id_, '<i>' .. result .. '</i>')
  end

  return {
    description = _msg('Returns a random fact!'),
    usage = {
      user = {
        '<code>!fact</code>',
        _msg('Returns a random fact.'),
      },
    },
    patterns = {
      _config.cmd .. 'fact$',
    },
    run = run
  }

end
