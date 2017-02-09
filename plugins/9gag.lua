do

  local function run(msg, matches)
    local b, c = http.request('http://api-9gag.herokuapp.com/')

    if c ~= 200 then
      return nil
    end

    local gag = json.decode(b)
    --random max json table size
    local i = math.random(#gag)
    local link_image = gag[i].src
    local title = gag[i].title

    if link_image:sub(0, 2) == '//' then
      link_image = link_image:sub(3, -1)
    end

    util.apiSendPhoto(msg, link_image, title)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns a random image from the latest 9gag posts.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/6'
        --'<code>!9gag</code>',
        --_msg('Send random image from 9gag'),
      },
    },
    patterns = {
      _config.cmd .. '9gag$'
    },
    run = run
  }

end
