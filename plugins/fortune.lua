do

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)

    if not os.execute('which fortune') then
      local text =  _msg('<b>sh: 1: %s: not found</b>\nPlease install <code>%s</code> and <code>%s</code> packages on your system.'):format('fortune')
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
