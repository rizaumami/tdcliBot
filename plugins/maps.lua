do

  local function run(msg, matches)
    local coord = util.getCoord(msg, matches[1])

    if coord then
      td.sendVenue(msg.chat_id_, msg.id_, 0, 1, nil, coord.lat, coord.lon, coord.formatted_address)
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns a location from Google Maps.'),
    usage = {
      user = {
        '<code>!loc [query]</code>',
        '<code>!location [query]</code>',
        '<code>!maps [query]</code>',
        _msg('Returns Google Maps of <code>[query]</code>.'),
        _msg('<b>Example</b>') .. ': <code>!loc raja ampat</code>',
      },
    },
    patterns = {
      _config.cmd .. 'maps (.*)$',
      _config.cmd .. 'location (.*)$',
      _config.cmd .. 'loc (.*)$',
    },
    run = run
  }

end
