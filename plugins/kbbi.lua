do

  local tagMap = {
    ['&#183;'] = '·',
    ['<sup>.-/sup>'] = '',
    ['<br/>'] = '\n',
    ['\\/'] = '/',
    ['—'] = '--',
    [' <b>1'] = '\n<b>1',
    [' <b>2'] = '\n<b>2',
    [' <b>3'] = '\n<b>3',
    [' <b>4'] = '\n<b>4',
    [' <b>5'] = '\n<b>5',
    [' <b>6'] = '\n<b>6',
    [' <b>7'] = '\n<b>7',
    [' <b>8'] = '\n<b>8',
    [' <b>9'] = '\n<b>9',
    [' <b>10'] = '\n<b>10'
  }

  local function cleanTag(html)
    for k, v in pairs(tagMap) do
      html = html:gsub(k, v)
    end
    return html
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local webkbbi = 'http://kbbi.web.id/'
    local lema = matches[2] and matches[1] .. '+' .. matches[2] or matches[1]
    local res, code = http.request(webkbbi .. lema .. '/ajax_0')
    local chat_id = msg.chat_id_
    local kbbi_desc

    if res == '' then
      return sendText(chat_id, msg.id_, 'Tidak ada arti kata "<b>' .. lema:gsub('+', ' ') .. '</b>" di kbbi.web.id')
    end

    if #matches == 2 then
      kbbi_desc = res:match('<b>%-%- ' .. matches[2] .. '.-<br\\/>')
    else
      local grabbedlema = res:match('{"x":1,"w":.-}')
      local jlema = json.decode(grabbedlema)

      if jlema.d:match('<br/>') then
        kbbi_desc = jlema.d:match('^.-<br/>')
      else
        kbbi_desc = jlema.d
      end
    end

    local footer = '\n' .. webkbbi .. lema
    local hasil = cleanTag(kbbi_desc .. footer)

    sendText(chat_id, msg.id_, hasil)
  end

--------------------------------------------------------------------------------

  return {
    description = 'Kamus Besar Bahasa Indonesia dari http://kbbi.web.id.',
    usage = {
      user = {
        '<code>!kbbi [lema]</code>',
        'Menampilkan arti dari <code>[lema]</code>'
      },
    },
    patterns = {
      _config.cmd .. 'kbbi (%w+)$',
      _config.cmd .. 'kbbi (%w+) (%w+)$'
    },
    run = run
  }

end
