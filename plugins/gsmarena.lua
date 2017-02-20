do

  local mime = require('mime')
  local function get_galink(msg, query)
    local burl = "https://api.datamarket.azure.com/Data.ashx/Bing/Search/Web?Query=%s&$format=json&$top=1"
    local burl = burl:format(URL.escape("'site:gsmarena.com intitle:" .. query .. "'"))
    local resbody = {}
    local bang, bing, bung = https.request{
        url = burl,
        headers = { ["Authorization"] = "Basic " .. mime.b64(":" .. _config.key.bing) },
        sink = ltn12.sink.table(resbody),
    }
    local dat = json.decode(table.concat(resbody))
    local jresult = dat.d.results

    if not util.emptyTable(jresult) then
      return jresult[1].Url
    end
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local phone = get_galink(msg, matches[2])
    local slug = phone:gsub('^.+/', '')
    local slug = slug:gsub('.php', '')
    local ibacor = 'http://ibacor.com/api/gsm-arena?view=product&slug='
    local res, code = http.request(ibacor .. slug)
    local gsm = json.decode(res)
    local phdata = {}

    if gsm == nil or gsm.status == 'error' or util.emptyTable(gsm.data) then
      local nogsm = _msg('<b>No phones found!</b>\n'
                    .. 'Request must be in the following format:\n')
                    .. '<code>!gsm brand type</code>'
      sendText(msg.chat_id_, msg.id_, nogsm)
      return
    end
    if not gsm.data.platform then
      gsm.data.platform = {}
    end
    if gsm.data.launch.status == 'Discontinued' then
      launch = gsm.data.launch.status .. '. Was announced in ' .. gsm.data.launch.announced
    else
      launch = gsm.data.launch.status
    end
    if gsm.data.platform.os then
      phdata[1] = '<b>OS</b>: ' .. gsm.data.platform.os
    end
    if gsm.data.platform.chipset then
      phdata[2] = '<b>Chipset</b>: ' .. gsm.data.platform.chipset
    end
    if gsm.data.platform.cpu then
      phdata[3] = '<b>CPU</b>: ' .. gsm.data.platform.cpu
    end
    if gsm.data.platform.gpu then
      phdata[4] = '<b>GPU</b>: ' .. gsm.data.platform.gpu
    end
    if gsm.data.camera.primary then
      local phcam = '<b>Camera</b>: ' .. gsm.data.camera.primary:gsub(',.*$', '') .. ', ' .. (gsm.data.camera.video or '')
      phdata[5] = phcam:gsub(', check quality', '')
    end
    if gsm.data.memory.internal then
      phdata[6] = '<b>RAM</b>: ' .. gsm.data.memory.internal
    end

    local gadata = table.concat(phdata, '\n')
    local title = '<b>' .. gsm.title .. '</b>\n\n'
    local dimensions = gsm.data.body.dimensions:gsub('%(.-%)', '')
    local display = gsm.data.display.size:gsub(' .*$', '"') .. ', '
        .. gsm.data.display.resolution:gsub('%(.-%)', '')
    local output = _msg('%s<b>Status</b>: %s\n'
        .. '<b>Dimensions</b>: %s\n'
        .. '<b>Weight</b>: %s\n'
        .. '<b>SIM</b>: %s\n'
        .. '<b>Display</b>: %s\n%s'
        .. '\n<b>MC</b>: %s\n'
        .. '<b>Battery</b>: %s\n'
        .. '<b>Pic</b>: %s\n'
        .. '<b>Link</b>: %s'):format(
      title,
      launch,
      dimensions,
      gsm.data.body.weight:gsub('%(.-%)', ''),
      gsm.data.body.sim,
      display,
      gadata,
      gsm.data.memory.card_slot,
      gsm.data.battery._empty_:gsub('battery', ''),
      gsm.img,
      phone
    )

    sendText(msg.chat_id_, msg.id_, output:gsub('<br>', ''))
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Returns mobile phone specification.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/57'
        --'<code>!phone [phone]</code>',
        --'<code>!gsm [phone]</code>',
        --_msg('Returns <code>phone</code> specification.'),
        --_msg('<b>Example</b>') .. ': <code>!gsm xiaomi mi4c</code>',
      },
    },
    patterns = {
      _config.cmd .. '(phone) (.*)$',
      _config.cmd .. '(gsmarena) (.*)$',
      _config.cmd .. '(gsm) (.*)$'
    },
    run = run,
    need_api_key = 'https://datamarket.azure.com/dataset/bing/search'
  }

end
