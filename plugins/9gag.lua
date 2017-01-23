do

  local function get_9GAG()
    local url = 'http://api-9gag.herokuapp.com/'
    local b,c = http.request(url)

    if c ~= 200 then
      return nil
    end

    local gag = json.decode(b)
    --random max json table size
    local i = math.random(#gag)
    local link_image = gag[i].src
    local title = gag[i].title

    if link_image:sub(0,2) == '//' then
      link_image = msg.text:sub(3,-1)
    end

    return link_image, title
  end

  local function run(msg, matches)
    local url, title = get_9GAG()
    util.apiSendPhoto(msg, url, title)
  end

  return {
    description = _msg('Returns a random image from the latest 9gag posts.'),
    usage = {
      user = {
        '<code>!9gag</code>',
        _msg('Send random image from 9gag'),
      },
    },
    patterns = {
      _config.cmd .. '9gag$'
    },
    run = run
  }

end
