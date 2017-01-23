do

  local function getWord(s, i)
    s = s or ''
    i = i or 1
    local t = {}

    for w in s:gmatch('%g+') do
      table.insert(t, w)
    end

    return t[i] or false
  end

  local function run(msg, matches)
    local input = msg.content_.text_:upper()

    if not input:match('%a%a%a TO %a%a%a') then
      return sendText(msg.chat_id_, msg.id_, _msg('<b>Example:</b> <code>!cash 5 USD to IDR</code>'))
    end

    local from = input:match('(%a%a%a) TO')
    local to = input:match('TO (%a%a%a)')
    local amount = getWord(input, 2)
    local amount = tonumber(amount) or 1
    local result = 1
    local url = 'https://www.google.com/finance/converter'

    if from ~= to then
      local url = url .. '?from=' .. from .. '&to=' .. to .. '&a=' .. amount
      local str, res = https.request(url)

      if res ~= 200 then
        return sendText(msg.chat_id_, msg.id_, _msg('<b>Connection error</b>'))
      end

      str = str:match('<span class=bld>(.*) %u+</span>')

      if not str then
        return sendText(msg.chat_id_, msg.id_, _msg('<b>Connection error</b>'))
      end

      result = string.format('%.2f', str):gsub('%.', ',')
    end

    local headerapi = '<b>' .. amount .. ' ' .. from .. ' = ' .. util.groupIntoThree(result) .. ' ' .. to .. '</b>\n\n'
    local source = _msg('Source: Google Finance\n<code>') .. os.date('%F %T %Z') .. '</code>'

    sendText(msg.chat_id_, msg.id_, headerapi .. source)
  end

  --------------------------------------------------------------------------------

  return {
    description = _msg('Returns (Google Finance) exchange rates for various currencies.'),
    usage = {
      user = {
        '<code>!cash [amount] [from] to [to]</code>',
        _msg('<b>Example</b>') .. ':',
        '  *  <code>!cash 5 USD to EUR</code>',
        '  *  <code>!currency 1 usd to idr</code>',
      },
    },
    patterns = {
      _config.cmd .. 'cash (.*)$',
      _config.cmd .. 'currency (.*)$',
    },
    run = run
  }

end
