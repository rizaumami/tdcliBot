do

  local function run(msg, matches)
    local jstr, res = https.request('https://api.github.com/repos/' .. matches[1] .. '/' .. matches[2])

    if res ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('Connection error'))
    end

    local jdat = json.decode(jstr)

    if not jdat.id then
      return sendText(msg.chat_id_, msg.id_, _msg('Shit happens'))
    end

    local description = '\n' .. util.escapeHtml(jdat.description) .. '\n\n' or '\n\n'
    local text =  jdat.html_url .. description
                  .. '<b>Language</b>: ' .. jdat.language
                  .. '\n<b>Fork</b>: ' .. jdat.forks_count
                  .. '\n<b>Star</b>: ' .. jdat.stargazers_count
                  .. '\n<b>Watcher</b>: ' .. jdat.subscribers_count
                  .. '\n\n• Last updated at ' .. jdat.updated_at:gsub('%a', ' ')

    sendText(msg.chat_id_, msg.id_, text)
  end

  return {
    description = _msg('Returns information about the specified GitHub repository.'),
    usage = {
      user = {
        '<code>github [username] [repository]</code>',
        _msg('Returns information about the specified GitHub repository.')
      },
    },
    patterns = {
      _config.cmd .. 'github (%w+) (.*)$'
    },
    run = run
  }

end
