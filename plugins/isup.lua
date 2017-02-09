do

  local function run(msg, matches)
    if not matches[1] then
      return
    end

    local protocol = http
    local url = matches[1]:lower()

    if url:match('^https') then
      protocol = https
    elseif not url:match('^http') then
      url = 'http://' .. matches[1]
    end

    local _, code = protocol.request(url)
    code = tonumber(code)
    local output

    if not code or code > 399 then
      output = _msg('This website is down or nonexistent 😱')
    else
      output = _msg('This website is up 😃')
    end

    sendText(msg.chat_id_, msg.id_, output)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns the up or down status of a website.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/66'
        --'<code>!isup github.com</code>',
        --_msg('Returns the up or down status of github.com.'),
      },
    },
    patterns = {
      _config.cmd .. 'isup (.*)$',
    },
    run = run
  }

end
