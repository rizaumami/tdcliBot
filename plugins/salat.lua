do

  local base_api = 'http://muslimsalat.com'
  local calculation = {
    [1] = 'Egyptian General Authority of Survey',
    [2] = 'University Of Islamic Sciences, Karachi (Shafi)',
    [3] = 'University Of Islamic Sciences, Karachi (Hanafi)',
    [4] = 'Islamic Circle of North America',
    [5] = 'Muslim World League',
    [6] = 'Umm Al-Qura',
    [7] = 'Fixed Isha'
  }

  local function getTime(lat, lng)
    local api = 'https://maps.googleapis.com/maps/api/timezone/json?'
    local timestamp = os.time(os.date('!*t'))
    local parameters = 'location=' .. lat .. ',' .. lng .. '&timestamp=' .. timestamp
    local res, code = https.request(api .. URL.escape(parameters))

    if code ~= 200 then
      return nil
    end

    local data = json.decode(res)

    if (data.status == 'ZERO_RESULTS') then
      return nil
    end
    if (data.status == 'OK') then
      return timestamp + data.rawOffset + data.dstOffset
    end
  end

  function toTwentyFour(twelvehour)
    local hour, minute, meridiem = string.match(twelvehour, '^(.-):(.-) (.-)$')
    local hour = tonumber(hour)

    if (meridiem == 'am') and (hour == 12) then
      hour = 0
    elseif (meridiem == 'pm') and (hour < 12) then
      hour = hour + 12
    end

    if hour < 10 then
      hour = '0' .. hour
    end

    return (hour .. ':' .. minute)
  end

--------------------------------------------------------------------------------

  function run(msg, matches)
    local area = matches[1]
    local method = 5
    local notif = ''
    local url = base_api .. '/' .. URL.escape(area) .. '.json'

    if matches[2] and matches[1]:match('%d') then
      local c_method = tonumber(matches[1])

      if c_method == 0 or c_method > 7 then
        local text = _msg('<b>Calculation method is out of range</b>\nConsult <code>!help salat</code>')
        return sendText(msg.chat_id_, msg.id_, text)
      else
        method = c_method
        url = base_api .. '/' .. URL.escape(matches[2]) .. '.json'
        notif = _msg('\n\n<b>Method:</b> ') .. calculation[method]
        area = matches[2]
      end
    end

    local res, code = http.request(url .. '/' .. method .. '?key=' .. _config.key.salat)

    if code ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('<b>Error</b>') .. ': <code>' .. code .. '</code>')
    end

    local salat = json.decode(res)
    local localTime = getTime(salat.latitude, salat.longitude)

    if salat.title == '' then
      salat_area = area .. ', ' .. salat.country
    else
      salat_area = salat.title
    end

    local is_salat_time = _msg('<b>Salat time for %s</b>\n\n'
          .. '<code>Time    : %s\n'
          .. 'Qibla   : %s°\n\n'
          .. 'Fajr    : %s\n'
          .. 'Sunrise : %s\n'
          .. 'Dhuhr   : %s\n'
          .. 'Asr     : %s\n'
          .. 'Maghrib : %s\n'
          .. 'Isha    : %s</code>'):format( salat_area,
                                            os.date('%T', localTime),
                                            salat.qibla_direction,
                                            toTwentyFour(salat.items[1].fajr),
                                            toTwentyFour(salat.items[1].shurooq),
                                            toTwentyFour(salat.items[1].dhuhr),
                                            toTwentyFour(salat.items[1].asr),
                                            toTwentyFour(salat.items[1].maghrib),
                                            toTwentyFour(salat.items[1].isha)
    ) .. notif

    sendText(msg.chat_id_, msg.id_, is_salat_time)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns todays prayer times.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/86'
        --'<code>!salat [area]</code>',
        --_msg('Returns todays prayer times for that area.\n'),
        --_msg('<b>Example</b>') .. ': <code>!salat bandung</code>',
        --'',
        --'<code>!salat [method] [area]</code>',
        --_msg('Returns todays prayer times for that area calculated by <code>[method]</code>:'),
        --'<b>1</b> = Egyptian General Authority of Survey',
        --'<b>2</b> = University Of Islamic Sciences, Karachi (Shafi)',
        --'<b>3</b> = University Of Islamic Sciences, Karachi (Hanafi)',
        --'<b>4</b> = Islamic Circle of North America',
        --'<b>5</b> = Muslim World League',
        --'<b>6</b> = Umm Al-Qura',
        --'<b>7</b> = Fixed Isha',
        --_msg('<b>Example</b>') .. ': <code>!salat 2 denpasar</code>',
      },
    },
    patterns = {
      _config.cmd .. 'salat (%a.*)$',
      _config.cmd .. 'salat (%d) (%a.*)$',
    },
    run = run,
    need_api_key = 'https://muslimsalat.com/panel/signup.php'
  }

end
