URL = require 'socket.url'
http = require 'socket.http'
multipart = require 'multipart-post'

http.TIMEOUT = 10

local U = {}  -- Main utilities table

-- Print message. For debugging purpose.
local function vardump(value)
  print '--------------------------------------------------------------- START'
  print(serpent.block(value, {comment=false}))
  print '--------------------------------------------------------------- STOP\n'
end

U.vardump = vardump

-- Is it a chat or a private message?
local function isChatMsg(msg)
  local chat_id = tostring(msg.chat_id_)
  if chat_id:match('^-') then
    return true
  else
    return false
  end
end

U.isChatMsg = isChatMsg

-- Is it a chat or a private message?
local function extractGUId(msg)
  local gid = msg.chat_id_
  local uid = msg.sender_user_id_
  local gid_str = tostring(gid)
  local uid_str = tostring(uid)
  return gid, uid, gid_str, uid_str
end

U.extractGUId = extractGUId

-- http://www.lua.org/manual/5.2/manual.html#pdf-io.popen
local function shellCommand(str)
  local cmd = io.popen(str)
  local result = cmd:read('*all')
  cmd:close()
  return result
end

U.shellCommand = shellCommand

local function isReply(msg)
  local r = false
  if msg.reply_to_message_id_ ~= 0 then  
     r = true
  end
  return r
end

U.isReply = isReply

local function emtpyTable(tbl)
  local t = false
  if next(tbl) == nil then
     t = true
  end
  return t
end

U.emtpyTable = emtpyTable

-- http://stackoverflow.com/a/11130774/3163199
local function scanDir(directory)
  local i, t, popen = 0, {}, io.popen
  for filename in popen('ls "' .. directory .. '"'):lines() do
    i = i + 1
    t[i] = filename
  end
  return t
end

U.scanDir = scanDir

local function groupIntoThree(number)
  while true do
    number, k = string.gsub(number, "^(-?%d+)(%d%d%d)", '%1.%2')

    if (k==0) then
      break
    end
  end
  return number
end

U.groupIntoThree = groupIntoThree

local function escapeHtml(str)
  return (string.gsub(str, "[}{\">/<'&]", {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;",
    ["/"] = "&#47;"
  }))
end

U.escapeHtml = escapeHtml

-- See http://stackoverflow.com/a/14899740
local function unescapeHtml(str)
  local gsub, char = string.gsub, string.char
  local map = {
    ['lt'] = '<',
    ['gt'] = '>',
    ['amp'] = '&',
    ['quot'] = '"',
    ['apos'] = "'"
  }

  local swap = function(orig, n, s)
    return (n == '' and map[s])
           or (n == '#' and tonumber(s)) and string.char(s)
           or (n == '#x' and tonumber(s, 16)) and string.char(tonumber(s, 16))
           or orig
  end
  return str:gsub('(&(#?x?)([%d%a]+);)', swap)
end

U.unescapeHtml = unescapeHtml

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do
    a[#a+1] = n
  end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

U.pairsByKeys = pairsByKeys

-- Gets coordinates for a location.
local function getCoord(msg, input)
  local url = 'https://maps.googleapis.com/maps/api/geocode/json?address=' .. URL.escape(input)

  local jstr, res = https.request(url)
  if res ~= 200 then
    td.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'Connection error.', 1)
    return
  end

  local jdat = json.decode(jstr)
  if jdat.status == 'ZERO_RESULTS' then
    td.sendText(msg.chat_id_, msg.id_, 0, 1, nil, 'ZERO_RESULTS', 1)
    return
  end

  return {
    lat = jdat.results[1].geometry.location.lat,
    lon = jdat.results[1].geometry.location.lng,
    formatted_address = jdat.results[1].formatted_address
  }
end

U.getCoord = getCoord

-- Trims whitespace from a string.
local function trim(str)
  local s = str:gsub('^%s*(.-)%s*$', '%1')
  return s
end

U.trim = trim

-- Make bot API request
local function makeRequest(method, msg, request_body)
  local response = {}
  local body, boundary = multipart.encode(request_body)

  local success, code, headers, status = https.request{
    url = 'https://api.telegram.org/bot' .. _config.api.token .. '/' .. method
          .. '?chat_id=' .. _config.bot.id,
    method = 'POST',
    headers = {
      ['Content-Type'] =  'multipart/form-data; boundary=' .. boundary,
      ['Content-Length'] = string.len(body),
    },
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response),
  }

  local respbody = table.concat(response or {"no response"})
  local jbody = json.decode(respbody)

  if jbody.ok then
    local bridge = serpent.dump({
        chat_id = msg.chat_id_,
        msg_id = msg.id_,
        caption = request_body.caption
    })
    db:hset('tgapibridge', jbody.result.date, bridge)

    return jbody.result
  else
    return 'Error: ' .. jbody.error_code .. ', ' .. jbody.description
  end
end

-- Send bot API message. Intended to send link formatted message.
local function apiSendMessage(msg, text, parse_mode, disable_web_page_preview)
  local response = makeRequest('sendMessage', msg, {
    text = tostring(text),
    parse_mode = parse_mode:lower(),
    disable_web_page_preview = tostring(disable_web_page_preview)
  })
  return response
end

U.apiSendMessage = apiSendMessage

-- Bot API can directly send photo from URL. This is a hack so tdcliBot no need
-- to download the photo first and then send it later.
-- See 9gag.lua for an example.
local function apiSendPhoto(msg, photo, caption)
  local response = makeRequest('sendPhoto', msg, {
    photo = photo,
    caption = caption
  })
  return response
end

U.apiSendPhoto = apiSendPhoto

local function apiSendVideo(msg, video, caption)
  local response = makeRequest('sendVideo', msg, {
    video = video,
    caption = caption,
  })
  return response
end

U.apiSendVideo = apiSendVideo

local function apiSendDocument(msg, document, caption)
  local response = makeRequest('sendDocument', msg, {
    document = document,
    caption = caption,
  })
  return response
end

U.apiSendDocument = apiSendDocument

return U
