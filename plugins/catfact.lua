do

  local function run(msg, matches)
    local url = 'http://catfacts-api.appspot.com/api/facts'
    local jstr, code = http.request(url)

    if code ~= 200 then
      return 'Connection error.'
    end

    local data = json.decode(jstr)
    local facts = '<i>' .. data.facts[1] .. '</i>'
    local output = util.isChatMsg(msg) and facts or _msg('<b>Cat Fact</b>\n') .. facts
    local msg_id = util.isChatMsg(msg) and msg.id_ or 0

    sendText(msg.chat_id_, msg_id, output)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns a cat fact.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/27'
        --'<code>!catfact</code>',
        --_msg('Returns a cat fact.'),
      },
    },
    patterns = {
      _config.cmd .. 'catfact$',
    },
    run = run
  }

end
