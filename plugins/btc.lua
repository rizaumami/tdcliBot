do

  -- See https://bitcoinaverage.com/api
  local function run(msg, matches)
    local base_url = 'https://api.bitcoinaverage.com/ticker/global/'
    local currency = 'USD'

    if matches[2] then
      currency = matches[2]:upper()
    end

    -- Do request on bitcoinaverage, the final / is critical!
    local res, code = https.request(base_url .. currency .. '/')

    if code ~= 200 then return nil end

    local data = json.decode(res)
    local ask = string.gsub(data.ask, '%.', ',')
    local bid = string.gsub(data.bid, '%.', ',')
    local index = '<b>BTC</b> in <b>' .. currency .. ':</b>\n'
        .. _msg('• Buy: ') .. util.groupIntoThree(ask) .. '\n'
        .. _msg('• Sell: ') .. util.groupIntoThree(bid)

    sendText(msg.chat_id_, msg.id_, index)
  end

  --------------------------------------------------------------------------------

  return {
    description = _msg('Displays the current Bitcoin price.'),
    usage = {
      user = {
        '<code>!btc</code>',
        _msg('Displays Bitcoin price in USD'),
        '',
        '<code>!btc [currency]</code>',
        _msg('Displays Bitcoin price in <code>[currency]</code>'),
        _msg('<code>[currency]</code> is in ISO 4217 format.'),
      },
    },
    patterns = {
      _config.cmd .. '(btc)$',
      _config.cmd .. '(btc) (%a%a%a)$',
    },
    run = run
  }

end
