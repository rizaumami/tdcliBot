do

  -- If you have a google api key for the geocoding/timezone api
  local need_api_key

  -- Use timezone api to get the time in the lat,
  -- Note: this needs an API key
  local function getTime(lat, lng)
    local api = 'https://maps.googleapis.com/maps/api/timezone/json?'

    -- Get a timestamp (server time is relevant here)
    -- Need the utc time for the google api
    local timestamp = os.time(os.date('!*t'))
    local parameters = 'location=' .. lat .. ',' .. lng .. '&timestamp=' .. timestamp

    if need_api_key ~= nil then
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

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local area = matches[1]
    local chat_id = msg.chat_id_
    local dateFormat = '%A, %F %T'

    if area == nil then
      sendText(chat_id, msg.id_, _msg('<b>The time in nowhere is never</b>'))
    end

    local coordinats, code = util.getCoord(msg, area)

    if not coordinats then
      sendText(chat_id, msg.id_, _msg('It seems that in "<b>%s</b>" they do not have a concept of time.'):format(area))
      return
    end

    local lat = coordinats.lat
    local long = coordinats.lon
    local localTime, timeZoneId = getTime(lat, long)

    local atime = _msg('The local time in <i>%s (%s)</i> is:\n<b>%s</b>'):format(area, timeZoneId, os.date(dateFormat, localTime))
    sendText(chat_id, msg.id_, atime)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns the time, date, and timezone for the given location.'),
    usage = {
      user = {
        'https://telegra.ph/Time-02-08',
        --'<code>!time [area]</code>',
        --_msg('Displays the local time in that <code>[area]</code>\n<b>Example</b>') .. ': <code>!time yogyakarta</code>',
      },
    },
    patterns = {
      _config.cmd .. 'time (.*)$'
    },
    run = run
  }

end

