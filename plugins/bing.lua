do

  local mime = require('mime')

  local function bingo(msg, burl, terms)
    local burl = burl:format(URL.escape("'" .. terms .. "'"))
    local limit = util.isChatMsg(msg) and 4 or 8
    local resbody = {}
    local bang, bing, bung = https.request{
        url = burl .. '&$top=' .. limit,
        headers = { ["Authorization"] = "Basic " .. mime.b64(":" .. _config.key.bing) },
        sink = ltn12.sink.table(resbody),
    }
    local dat = json.decode(table.concat(resbody))
    local jresult = dat.d.results

    if util.emptyTable(jresult) then
      sendText(msg.chat_id_, msg.id_, _msg('<b>No Bing results for</b>: ') .. terms)
    else
      local reslist = {}

      for i = 1, #jresult do
        local result = jresult[i]
        reslist[i] =  '<b>' .. i .. '</b>. '
                      .. '<a href="' .. result.Url:gsub('[!]', '%%21') .. '">'
                      .. result.Title .. '</a>'
      end

      local reslist = table.concat(reslist, '\n')
      local header = _msg('<b>Bing results for</b> <i>%s</i> <b>:</b>\n'):format(terms)
      util.apiSendMessage(msg, header .. reslist, 'HTML', true)
    end
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local burl = "https://api.datamarket.azure.com/Data.ashx/Bing/Search/Web?Query=%s&$format=json"
    local chat_id = msg.chat_id_
    burl = matches[1] == 'nsfw' and burl .. '&Adult=%%27Off%%27' or burl .. '&Adult=%%27Strict%%27'

    if util.isReply(msg) then
      td.getMessage(chat_id, msg.reply_to_message_id_, function(a, d)
        bingo(a.msg, a.burl, d.content_.text_)
      end, {msg=msg, burl=burl, cmd='bing'})
    else
      bingo(msg, burl, matches[2])
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg("Returns 4 (group) or 8 (private) Bing's top search results for the given query.\n"
        .. 'Safe search is enabled by default, use <code>!bnsfw</code> or <code>!bingnsfw</code> to disable it.'),
    usage = {
      --sudo = {
        --'<code>!setapikey bing [need_api_key]</code>',
        --_msg('Set Bing API key.'),
        --'',
      --},
      user = {
        'See: https://t.me/tdclibotmanual/18'
        --'<code>!bing [terms]</code>',
        --'<code>!b [terms]</code>',
        --_msg('Safe searches Bing'),
        --'',
        --'<code>!bing</code>',
        --'<code>!b</code>',
        --_msg('Safe searches Bing by reply. The search terms is the replied message text.'),
        --'',
        --'<code>!bingnsfw [terms]</code>',
        --'<code>!bnsfw [terms]</code>',
        --_msg('Searches Bing (include NSFW)'),
        --'',
        --'<code>!bingnsfw</code>',
        --'<code>!bnsfw</code>',
        --_msg('Searches Bing (include NSFW). The search terms is the replied message text.'),
        --'',
      },
    },
    patterns = {
      _config.cmd .. '(b)$',
      _config.cmd .. '(bing)$',
      _config.cmd .. 'b(nsfw)$',
      _config.cmd .. 'bing(nsfw)$',
      _config.cmd .. '(b) (.*)$',
      _config.cmd .. '(bing) (.*)$',
      _config.cmd .. 'b(nsfw) (.*)$',
      _config.cmd .. 'bing(nsfw) (.*)$',

    },
    run = run,
    need_api_key = 'https://datamarket.azure.com/dataset/bing/search'
  }

end
