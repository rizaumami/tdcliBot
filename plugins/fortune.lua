do

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)

    if not os.execute('which fortune') then
      local text =  _msg('<b>sh: 1: fortune: not found</b>'
                    .. '\nPlease install <code>fortune</code> and <code>fortunes</code> packages on your system.')
      return sendText(chat_id, msg.id_, text)
    end

    local fortunef = io.popen('fortune')
    local output = '<pre>' .. fortunef:read('*all') .. '</pre>'
    fortunef:close()
    sendText(chat_id, msg.id_, output)
  end

--------------------------------------------------------------------------------

  return {
    description = 'Returns UNIX fortunes.',
    usage = {
      user = {
        '<code>!fortune</code>',
        'Returns UNIX fortunes.',
        '',
      },
    },
    patterns = {
      _config.cmd .. 'fortune$',
    },
    run = run,
  }

end
