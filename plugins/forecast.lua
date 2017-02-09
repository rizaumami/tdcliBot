do

  local function round(val, decimal)
    local exp = decimal and 10^decimal or 1
    return math.ceil(val * exp - 0.5) / exp
  end

  local function wemoji(weather_data)
    if weather_data.icon == 'clear-day' then
    return '☀️'
    elseif weather_data.icon == 'clear-night' then
      return '🌙'
    elseif weather_data.icon == 'rain' then
      return '☔️'
    elseif weather_data.icon == 'snow' then
    return '❄️'
    elseif weather_data.icon == 'sleet' then
      return '🌨'
    elseif weather_data.icon == 'wind' then
      return '💨'
    elseif weather_data.icon == 'fog' then
      return '🌫'
    elseif weather_data.icon == 'cloudy' then
      return '☁️☁️'
    elseif weather_data.icon == 'partly-cloudy-day' then
      return '🌤'
    elseif weather_data.icon == 'partly-cloudy-night' then
      return '🌙☁️'
    else
      return ''
    end
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    -- Use timezone api to get the time in the lat
    local coords, code = util.getCoord(msg, matches[1])
    local lat = coords.lat
    local long = coords.lon
    local address = coords.formatted_address
    local url = 'https://api.darksky.net/forecast/'
    local units = '?units=si'
    local url = url .. _config.key.forecast .. '/' .. URL.escape(lat) .. ',' .. URL.escape(long) .. units
    local res, code = https.request(url)

    if code ~= 200 then
      return nil
    end

    local jcast = json.decode(res)
    local todate = os.date('%A, %F', jcast.currently.time)

    local forecast = _msg('<b>Weather for: %s</b>\n%s\n\n'
        .. '<b>Right now</b> %s\n%s - Feels like %s°C\n\n'
        .. '<b>Next 24 hours</b> %s\n%s\n\n'
        .. '<b>Next 7 days</b> %s\n%s\n\n'):format( address,
                                                    todate,
                                                    wemoji(jcast.currently),
                                                    jcast.currently.summary,
                                                    round(jcast.currently.apparentTemperature),
                                                    wemoji(jcast.hourly),
                                                    jcast.hourly.summary,
                                                    wemoji(jcast.daily),
                                                    jcast.daily.summary
    )
    sendText(msg.chat_id_, msg.id_, forecast)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns the current weather conditions for a given location.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/51'
        --'<code>!cast [area]</code>',
        --'<code>!forecast [area]</code>',
        --'<code>!weather [area]</code>',
        --_msg('Forecast for that <code>[area]</code>.'),
        --_msg('<b>Example</b>') .. ': <code>!weather dago parung panjang</code>',
      },
    },
    patterns = {
      _config.cmd .. 'cast (.*)$',
      _config.cmd .. 'forecast (.*)$',
      _config.cmd .. 'weather (.*)$',
    },
    run = run,
    need_api_key = 'https://darksky.net/dev/'
  }

end
