do

  local function yandexTranslate(chat_id, msg_id, language, text)
    local url = 'https://translate.yandex.net/api/v1.5/tr.json/translate?key='
                .. _config.key.translate .. '&lang=' .. language .. '&text=' .. URL.escape(text)
    print(url)
    local str, res = https.request(url)
    local jstr = json.decode(str)

    if jstr.code == 200 then
      sendText(chat_id, msg_id, jstr.text[1])
    else
      sendText(chat_id, msg_id, jstr.message)
    end
  end

  function translateByReply(arg, data)
    util.vardump(arg)
    util.vardump(data)
    yandexTranslate(arg.chat_id, data.id_, arg.lang, data.content_.text_)
  end

  local function run(msg, matches)
    local chat_id = msg.chat_id_
    local msg_id = msg.id_
    local botslang = _config.language.default

    if (msg.reply_to_message_id_ ~= 0) then
      local replied_id = msg.reply_to_message_id_
      local pattern = {}

      -- translate en - translate en-id
      if matches[1] == '!tl' or matches[1] == '!translate' then
        pattern = {chat_id = chat_id, lang = botslang}
      else
        pattern = {chat_id = chat_id, lang = matches[1]}
      end

      td.getMessage(chat_id, replied_id, translateByReply, pattern)
    else
      -- translate id-en uji - translate en uji
      if matches[1] == 'tl' or matches[1] == 'translate' then
        yandexTranslate(chat_id, msg_id, botslang, matches[2])
      elseif matches[1]:match('%a%a') or matches[1]:match('%a%a-%a%a') then
        yandexTranslate(chat_id, msg_id, matches[1]:gsub(',', '-'), matches[2])
      end
    end
  end

  return {
    description = _msg("Translates input or the replied-to message into the bot's language."),
    usage = {
      user = {
        '<code>!trans text</code>',
        _msg('Translate the <code>text</code> into the default language (or english).\n<b>Example</b>') .. ': <code>!trans terjemah</code>',
        '',
        '<code>!trans target_lang text</code>',
        _msg('Translate the <code>text</code> to <code>target_lang</code>.\n<b>Example</b>') .. ': <code>!trans en terjemah</code>',
        '',
        '<code>!trans source-target text</code>',
        _msg('Translate the <code>source</code> to <code>target</code>.\n<b>Example</b>') .. ': <code>!trans id,en terjemah</code>',
        '',
        _msg('<b>Use</b> <code>!translate</code> <b>when reply!</b>'),
        '',
        '<code>!translate</code>',
        _msg('By reply. Translate the replied text into the default language (or english).'),
        '',
        '<code>!translate target_lang</code>',
        _msg('By reply. Translate the replied text into <code>target_lang</code>.'),
        '',
        '<code>!translate source-target</code>',
        _msg('By reply. Translate the replied text <code>source</code> to <code>target</code>.'),
        '',
        _msg('Languages are two letter ISO 639-1 language code.'),
      },
    },
    patterns = {
      _config.cmd .. 'tl$',
      _config.cmd .. 'translate$',
      _config.cmd .. 'tl (%a%a)$',
      _config.cmd .. 'translate (%a%a)$',
      _config.cmd .. 'tl (%a%a) (.+)$',
      _config.cmd .. 'translate (%a%a) (.+)$',
      _config.cmd .. 'tl (%a%a,%a%a) (.+)$',
      _config.cmd .. 'translate (%a%a,%a%a) (.+)$',
    },
    run = run,
    need_api_key = 'http://tech.yandex.com/keys/get'
  }

end
