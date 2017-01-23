do

  -- If you have a google api key for the geocoding/timezone api
  local need_api_key  = nil
  local dateFormat = '%A, %F %T'

  -- Need the utc time for the google api
  local function utctime()
    return os.time(os.date('!*t'))
  end

  -- Use timezone api to get the time in the lat,
  -- Note: this needs an API key
  local function getTime(lat, lng)
    local api = 'https://maps.googleapis.com/maps/api/timezone/json?'

    -- Get a timestamp (server time is relevant here)
    local timestamp = utctime()
    local parameters = 'location=' .. lat .. ',' .. lng .. '&timestamp=' .. timestamp

    if need_api_key ~=nil then
      parameters = URL.escape(parameters) .. '&key=' .. need_api_key
    end

    local res,code = https.request(api .. parameters)

    if code ~= 200 then
      return nil
    end

    local data = json.decode(res)

    if (data.status == 'ZERO_RESULTS') then
      return nil
    end
    if (data.status == 'OK') then
      -- Construct what we want
      -- The local time in the location is: timestamp + rawOffset + dstOffset
      local localTime = timestamp + data.rawOffset + data.dstOffset
      return localTime, data.timeZoneId
    end
    return localTime
  end

  local function getformattedLocalTime(msg, area)
    if area == nil then
      sendText(msg.chat_id_, msg.id_, _msg('<b>The time in nowhere is never</b>'))
    end

    local coordinats, code = util.getCoord(msg, area)

    if not coordinats then
      sendText(msg.chat_id_, msg.id_, _msg('It seems that in "<b>%s</b>" they do not have a concept of time.'):format(area))
      return
    end

    local lat = coordinats.lat
    local long = coordinats.lon
    local localTime, timeZoneId = getTime(lat, long)

    local atime = _msg('The local time in <i>%s (%s)</i> is:\n<b>%s</b>'):format(area, timeZoneId, os.date(dateFormat,localTime))
    sendText(msg.chat_id_, msg.id_, atime)
  end

  local function run(msg, matches)
    return getformattedLocalTime(msg, matches[1])
  end

  return {
    description = _msg('Returns the time, date, and timezone for the given location.'),
    usage = {
      user = {
        '<code>!time [area]</code>',
        _msg('Displays the local time in that <code>[area]</code><b>Example</b>') .. ': <code>!time yogyakarta</code>',
      },
    },
    patterns = {
      _config.cmd .. 'time (.*)$'
    },
    run = run
  }

end

