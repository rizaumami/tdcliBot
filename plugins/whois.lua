-- dependency: whois
-- install on your system, e.g sudo aptitude install whois

do

  local whofile = '/tmp/whois.txt'

  local function whoinfo()
    local file = io.open(whofile, 'r')
    local content = file:read "*a"
    file:close()
    return content:sub(1, 4000)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)
    local url = matches[1]:gsub('^.-//', '')
    local result = os.execute('whois "' .. url .. '" > ' .. whofile)

    if not result then
      if whoinfo():match('no match') then
        local text = _msg('<b>No match for</b> %s'):format(matches[1])
        sendText(chat_id, msg.id_, text)
      elseif not os.execute('which whois') then
        local text =  _msg('<b>sh: 1: whois: not found</b>'
                      .. '\nPlease install <code>whois</code> package on your system.')
        sendText(chat_id, msg.id_, text)
      end
      return
    end

    if matches[2] then
      if matches[2] == 'txt' then
        td.sendDocument(chat_id, msg.id_, 0, 1, nil, whofile)
      elseif matches[2] == 'pm' and util.isChatMsg(msg) then
        td.sendText(msg.sender_user_id_, 0, 0, 1, nil, whoinfo(), 1, nil)
      elseif matches[2] == 'pmtxt' and util.isChatMsg(msg) then
        td.sendDocument(msg.sender_user_id_, 0, 0, 1, nil, whofile)
      end
    else
      td.sendText(chat_id, msg.id_, 0, 1, nil, whoinfo(), 1, nil)
    end
  end

--------------------------------------------------------------------------------

  return {
    description = 'Whois lookup.',
    usage = {
      user = {
        'https://telegra.ph/Whois-02-08',
        --'<code>!whois [url]</code>',
        --'Returns whois lookup for <code>[url]</code>',
        --'',
        --'<code>!whois [url] txt</code>',
        --'Returns whois lookup for <code>[url]</code> and then send as text file.',
        --'',
        --'<code>!whois [url] pm</code>',
        --'Returns whois lookup for <code>[url]</code> into requester PM.',
        --'',
        --'<code>!whois [url] pmtxt</code>',
        --'Returns whois lookup file for <code>[url]</code> and then send into requester PM.',
        --'',
      },
    },
    patterns = {
      _config.cmd .. 'whois (%g+)$',
      _config.cmd .. 'whois (%g+) (txt)$',
      _config.cmd .. 'whois (%g+) (pm)$',
      _config.cmd .. 'whois (%g+) (pmtxt)$'
    },
    run = run
  }

end
