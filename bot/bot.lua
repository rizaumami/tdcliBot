package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  .. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'


-- VARIABLES -------------------------------------------------------------------

https = require 'ssl.https'
ltn12 = require 'ltn12'
json = require 'cjson'
db = (loadfile './bot/libs/redis.lua')()
serpent = require 'serpent'
td = (loadfile './bot/libs/tdcli.lua')()
util = (loadfile './bot/utils.lua')()

config_file = './bot/config.lua'

-- The message structure is lack of its sender identifications
-- Set line below to "true" to append sender first_name_, last_name_, and username_ to the message
-- NOTE: This will requesting getUser for every valid messages, I'm not quite sure for its implications.
local append_ids_to_msg = false
local last_cron


-- FUNCTIONS -------------------------------------------------------------------

-- An alias to sendText.
function sendText(chat_id, reply_to_message_id, text, disable_web_page_preview, parse_mode, cb, cmd)
  local parse_mode = parse_mode or 'HTML'
  local disable_web_page_preview = disable_web_page_preview or 1
  local message = {}
  local n = 1
  -- If text is longer than 4096 chars, send multiple messages.
  -- https://core.telegram.org/method/messages.sendMessage
  while #text > 4096 do
    message[n] = text:sub(1, 4096)
    text = text:sub(4096, #text)
    parse_mode = nil
    n = n + 1
  end
  message[n] = text

  for i = 1, #message do
    local reply = i > 1 and 0 or reply_to_message_id
    td.sendText(chat_id, reply, 0, 1, nil, message[i], disable_web_page_preview, parse_mode, cb, cmd)
  end
end

-- Save serialized data into a file. Set uglify true to minify the file.
function saveConfig(data, file, extra)
  local data = data or _config
  local file = file or config_file
  file = io.open(file, 'w+')
  local serialized = serpent.block(data, {comment = false, name = '_'})

  if extra then
    if extra == 'noname' then
      serialized = serpent.block(data, {comment=false})
    else
      serialized = serpent.dump(data)
    end
  end
  file:write(serialized)
  file:close()
end

function fileExists(name)
  local exist = false
  if name then
    local f = io.open(name, 'r')
    if f ~= nil then
      io.close(f)
      exist = true
    end
  end
  return exist
end

-- Print text in colour
local function prtInClr(colour, str)
  if (colour == 'Red') then
    print('\27[31m' .. str .. '\27[39m')
  elseif (colour == 'Green') then
    print('\27[32m' .. str .. '\27[39m')
  elseif (colour == 'Brown') then
    print('\27[33m' .. str .. '\27[39m')
  end
end

-- Returns bot api properties (as getMe method)
local function apiGetMe(token)
  local response = {}
  local getme  = https.request{
    url = 'https://api.telegram.org/bot' .. token .. '/getMe',
    method = "POST",
    sink = ltn12.sink.table(response),
  }
  local body = table.concat(response or {"no response"})
  local jbody = json.decode(body)

  if jbody.ok then
    botid = jbody.result
  else
    print('Error: ' .. jbody.error_code .. ', ' .. jbody.description)
    botid = {id = '', username = ''}
  end

  return botid
end

-- Non bot account cannot send link formatted text.
-- So, we need an bot API account for this.
local function getBotApiIds(config)
  prtInClr('Brown', '\n Some functions and plugins using bot API as sender.\n'
      .. ' Please provide bots API token to ensure it\'s works as intended.\n'
      .. ' You can ENTER to skip and then fill the required info into ' .. config_file .. '\n')

  io.write ('\27[1m Input your bot API key (token) here: \27[0;39;49m')

  local token = io.read()
  local bot = apiGetMe(token)
  config.api = {
    token = token,
    id = bot.id,
    first_name = bot.first_name,
    username = bot.username
  }

  saveConfig(config)
end

-- Returns the config from config.lua file. If file doesn't exist, create it.
local function loadConfig()
  if not fileExists(config_file) then
    -- A simple config with basic plugins and ourselves as privileged user
    _config = {
      administrators = {},
      api = {},
      bot = {},
      db = 2,
      chats = {disabled = {}, managed = {}},
      cmd = '^[/!#]',
      key = {},
      language = {
        allow_fuzzy_translations = false,
        available_languages = {},
        default = 'en',
      },
      plugins = {
        path = {['sys'] = 'bot/plugins/', ['usr'] = 'plugins/'},
        sys = {
          'administration',
          'banhammer',
          'channels',
          'groupmanager',
          'help',
          'plugins',
          'setlang',
          'sudo',
          'whitelist'
        },
        usr = {
          '9gag',
          'apod',
          'base64',
          'binary',
          'bing',
          'boobs',
          'btc',
          'calc',
          'catfact',
          'cats',
          'commit',
          'currency',
          'dilbert',
          'doge',
          'echo',
          'exec',
          'fact',
          'forecast',
          'github',
          'gsmarena',
          'hackernews',
          'hexcolor',
          'id',
          'imdb',
          'isup',
          'kbbi',
          'maps',
          'patterns',
          'qr',
          'quran',
          'reddit',
          'salat',
          'time',
          'translate',
          'unicode',
          'urbandictionary',
          'whois',
          'wikipedia',
          'xkcd',
          'yify'
        },
      },
      sudoers = {},
      whitelist = false
    }
    saveConfig()
    prtInClr('Green', ' Created new config file: ' .. config_file)
  end

  local config = loadfile(config_file)()

  if not config.api.token or config.api.token == '' then
    getBotApiIds(config)
  end

  for i = 1, #config.sudoers do
    print('Allowed user: ' .. #config.sudoers[i])
  end

  return config
end

function loadPlugins()
  if not _config then return end

  for ptype, ppath in pairs(_config.plugins.path) do
    for i = 1, #_config.plugins[ptype] do
      local plugin = _config.plugins[ptype][i]
      print('Loading plugin', plugin)
      local ok, err =  pcall(function()
        plug = loadfile(ppath .. plugin .. '.lua')()
        plugins[plugin] = plug
      end)

      if not ok then
        if plugin == nil then break end
        prtInClr('Brown', 'Error loading plugin ' .. plugin .. '\n' .. err)
      end
      if plug.need_api_key then
        local keyname = _config.key[plugin]

        if not keyname or keyname == '' then
          table.remove(_config.plugins[ptype], i)
          prtInClr('Brown', plugin .. '.lua is missing its api key. Will not be enabled.')
        end
      end
      saveConfig()
    end
  end
end

-- Is received message valid?
local function msgValid(msg, block_self)
  -- Don't process outgoing messages
  --if msg.send_state_.ID_ = "MessageIsSuccessfullySent" or
    --msg.send_state_.ID_ = "messageIsBeingSent" or
    --msg.send_state_.ID_ = "messageIsFailedToSend" then
      --prtInClr('Red', 'Not valid: Message from us')
      --return false
   --end
  -- Before bot was started
  if msg.date_ < now then
    prtInClr('Red', 'Not valid: old msg')
    return false
  end
  if not msg.chat_id_ then
    prtInClr('Red', 'Not valid: To id not provided')
    return false
  end
  if not msg.sender_user_id_ then
    prtInClr('Red', 'Not valid: Sender id not provided')
    return false
  end
  if msg.sender_user_id_ == 777000 then
    prtInClr('Red', 'Not valid: Telegram message')
    return false
  end
  if (block_self and msg.sender_user_id_ == my_id) then
    prtInClr('Red', 'Not valid: Message from our id')
    return false
  end

  return true
end

-- Returns a table with matches or nil
local function matchPattern(pattern, text)
  if text then
    local matches = { string.match(text, pattern) }
    if next(matches) then
      return matches
    end
  end
end

-- Check if plugin is on _config.plugins.disabled_on_chat table
local function isPluginDisabledOnChat(plugin_name, receiver)
  local disabled_chats = _config.plugins.disabled_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin, disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = _msg('Plugin %s is disabled on this chat'):format(disabled_plugin)
        print(warning)
        sendText(msg.chat_id_, msg.id_, warning)
        return true
      end
    end
  end
  return false
end

function getRank(user_id, chat_id)
  -- Return 5 if the user_id is the bot or sudoers.
  if _config.sudoers[user_id] then
    return 5, 'a sudoer'
  end
  -- Return 4 if the user_id is an administrator.
  if _config.administrators[user_id] then
    return 4, 'an administrator'
  end
  if _config.chats.managed[chat_id] then
    -- Return 3 if the user_id is the governor of the chat_id.
    if db:hexists('owner' .. chat_id, user_id) then
      return 3, 'an owner'
    elseif db:hexists('moderators' .. chat_id, user_id) then
    -- Return 2 if the user_id is a moderator of the chat_id.
      return 2, 'a moderator'
    elseif db:hexists('bans' .. chat_id, user_id) then
    -- Return 0 if the user_id is banned from the chat_id.
      return 0, 'is banned'
    -- Return 1 if antihammer is enabled.
    elseif db:hget('anti' .. chat_id, 'hammer') == 'true' then
      return 1, 'is banned, but allowed in this group'
    end
  end
  -- Return 0 if the user_id is globally banned (and antihammer is not enabled).
  if db:exists('globalbans') and db:hexists('globalbans', user_id)then
    return 0
  end
  -- Return 1 if the user_id is a regular user.
  return 1
end

-- Is bots id already saved in config.lua?
local function setMyId(id)
  if not _config.sudoers[id] then
    _config.sudoers[id]= id
    saveConfig()
  end
  if not _config.bot.id then
    _config.bot.id = id
    saveConfig()
  end
end

-- Run the plugin
local function runPlugin(msg, matches, plugin)
  if plugin.run then
    -- If plugin is for privileged users only
    if plugin.privilege and plugin.privilege > getRank(msg.sender_user_id_) then
      local unprivileged = _msg('This plugin requires privileged user.')
      return sendText(msg.chat_id_, msg.id_, unprivileged)
    else
      local result = plugin.run(msg, matches)
      if result then
        sendText(msg.chat_id_, msg.id_, result)
      end
    end
  end
end

-- Append user IDs into the message
local function appendIds(arg, data)
  local msg = arg.msg
  msg.first_name_ = data.first_name_
  msg.last_name_ = data.last_name_
  msg.type_ = data.type_
  msg.username_ = data.username_

  runPlugin(msg, arg.matches, arg.plugin)
end


-- MAIN ------------------------------------------------------------------------

_config = loadConfig()
_msg = require('./bot/languages').translate
-- Set _config.db so it won't clashed with another bots redis databases.
db:select(_config.db or 0)
plugins = {}
loadPlugins()

function tdcli_update_callback(data)
  --util.vardump(data)
  if (data.ID == 'UpdateNewMessage') then
    if data.message_ and msgValid(data.message_) then
      local msg = data.message_
      -- Until now, tg-cli unable to send link formatted message, here's our trick:
      -- 1. send output using bot api and set record in redis: db:hset('toforward', msg.date, msg.chat_id_)
      -- 2. match bot api message and forward to its original request chat
      -- See bing.lua and reddit.lua for example
      if msg.chat_id_ == _config.api.id then
        local hash = 'tgapibridge'
        local tgl = msg.date_

        if db:hexists(hash, tgl) then
          local sm = db:hget(hash, tgl)
          local tg = loadstring(sm)()
          if msg.content_.ID == 'MessagePhoto' then
            local photo = msg.content_.photo_.sizes_[0].photo_.persistent_id_
            td.sendPhoto(tg.chat_id, tg.msg_id, 0, 1, nil, photo, tg.caption)
          elseif msg.content_.ID == 'MessageAnimation' then
            local animation = msg.content_.animation_.animation_.persistent_id_
            td.sendAnimation(tg.chat_id, tg.msg_id, 0, 1, nil, animation, 0, 0, tg.caption)
          else
            td.forwardMessages(tg.chat_id, msg.chat_id_, {[0] = msg.id_}, 0)
          end
          db:hdel(hash, tgl)
        end
      end
      -- Go over enabled plugins patterns.
      for name, plugin in pairs(plugins) do
        -- Apply plugin.pre_process function
        if plugin.pre_process then
          print('Preprocess', name)
          msg = plugin.pre_process(msg)
        end
        -- Go over patterns. If one matches it's enough.
        for p = 1, #plugin.patterns do
          local pattern = plugin.patterns[p]
          local input = msg.content_.text_ or msg.content_.caption_
          local matches = matchPattern(pattern, input)

          if matches then
            print('msg matches: ', pattern)
            if isPluginDisabledOnChat(name, msg.chat_id_) then
              return nil
            end
            if not append_ids_to_msg then
              -- Run the plugin.
              runPlugin(msg, matches, plugin)
            else
              -- Append sender IDs into their message.
              td.getUser(msg.sender_user_id_, appendIds, {
                  msg = msg,
                  matches = matches,
                  plugin = plugin
              })
            end
          end
        end
      end
    end
  elseif (data.ID == 'UpdateOption' and data.name_ == 'my_id') then
    local id = data.value_.value_
    -- Is bots id already saved in config.lua?
    if not _config.sudoers[id] then
      _config.sudoers[id]= id
      saveConfig()
    end
    if not _config.bot.id then
      _config.bot.id = id
      saveConfig()
    end

    tdcli_function ({
      ID= 'GetChats',
      offset_order_ = '9223372036854775807',
      offset_chat_id_ = 0,
      limit_ = 20
    }, dl_cb, nil)
  end
  -- Run cron jobs every minute.
  if last_cron ~= os.date('%M') then
    last_cron = os.date('%M')
    for name, plugin in pairs(plugins) do
      if plugin.cron then -- Call each plugin's cron function, if it has one.
        plugin.cron()
      end
    end
  end
end

-- Start and load values
now = os.time()
math.randomseed(now)
started = false
