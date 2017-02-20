do

  local function run(msg, matches)
    local chat_id = msg.chat_id_
    local jstr, res = https.request('https://api.github.com/repos/' .. matches[1] .. '/' .. matches[2])

    if res ~= 200 then
      return sendText(chat_id, msg.id_, _msg('Connection error'))
    end

    local jdat = json.decode(jstr)

    if not jdat.id then
      return sendText(chat_id, msg.id_, _msg('Shit happens'))
    end

    local description = '\n' .. util.escapeHtml(jdat.description) .. '\n\n' or '\n\n'
    local text = _msg('%s%s<b>Language</b>: %s\n<b>Fork</b>: %s\n<b>Star</b>: %s\n<b>Watcher</b>: %s\n\n• Last updated at %s'):format(
      jdat.html_url,
      description,
      jdat.language,
      jdat.forks_count,
      jdat.stargazers_count,
      jdat.subscribers_count,
      jdat.updated_at:gsub('%a', ' ')
    )

    sendText(chat_id, msg.id_, text)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns information about the specified GitHub repository.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/54'
        --'<code>github [username] [repository]</code>',
        --_msg('Returns information about the specified GitHub repository.')
      },
    },
    patterns = {
      _config.cmd .. 'github (%w+) (.*)$'
    },
    run = run
  }

end
