do

  local function run(msg, matches)
    local output = http.request('http://whatthecommit.com/index.txt') or 'Minor text fixes'
    sendText(msg.chat_id_, msg.id_, '<pre>' .. output .. '</pre>')
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns a commit message from whatthecommit.com.'),
    usage = {
      user = {
        'See: http://telegra.ph/Commit-02-09'
        --'<code>!commit</code>',
        --_msg('Returns a commit message from whatthecommit.com.'),
      },
    },
    patterns = {
      _config.cmd .. 'commit$',
    },
    run = run
  }

end
