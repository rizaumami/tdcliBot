do

  local function getLanguageArguments(language)
    if language == 'c_gcc' or language == 'gcc' or language == 'c' or language == 'c_clang' or language == 'clang' then
      return '-Wall -std=gnu99 -O2 -o a.out source_file.c'
    elseif language == 'cpp' or language == 'cplusplus_clang' or language == 'cpp_clang' or language == 'clangplusplus' or language == 'clang++' then
      return '-Wall -std=c++14 -O2 -o a.out source_file.cpp'
    elseif language == 'visual_cplusplus' or language == 'visual_cpp' or language == 'vc++' or language == 'msvc' then
      return 'source_file.cpp -o a.exe /EHsc /MD /I C:\\\\boost_1_60_0 /link /LIBPATH:C:\\\\boost_1_60_0\\\\stage\\\\lib'
    elseif language == 'visual_c' then
      return 'source_file.c -o a.exe'
    elseif language == 'd' then
      return 'source_file.d -ofa.out'
    elseif language == 'golang' or language == 'go' then
      return '-o a.out source_file.go'
    elseif language == 'haskell' then
      return '-o a.out source_file.hs'
    elseif language == 'objective_c' or language == 'objc' then
      return '-MMD -MP -DGNUSTEP -DGNUSTEP_BASE_LIBRARY=1 -DGNU_GUI_LIBRARY=1 -DGNU_RUNTIME=1 -DGNUSTEP_BASE_LIBRARY=1 -fno-strict-aliasing -fexceptions -fobjc-exceptions -D_NATIVE_OBJC_EXCEPTIONS -pthread -fPIC -Wall -DGSWARN -DGSDIAGNOSE -Wno-import -g -O2 -fgnu-runtime -fconstant-string-class=NSConstantString -I. -I /usr/include/GNUstep -I/usr/include/GNUstep -o a.out source_file.m -lobjc -lgnustep-base'
    end
    return false
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    if #matches > 2 then return end

    local language = matches[1]
    local code = matches[2]
    local args = getLanguageArguments(language)

    if not args then
      args = ''
    end

    local parameters = {
      ['LanguageChoice'] = language,
      ['Program'] = code,
      ['Input'] = 'stdin',
      ['CompilerArgs'] = args
    }
    local response = {}
    local body, boundary = multipart.encode(parameters)
    local jstr, res = http.request(
      {
        ['url'] = 'http://rextester.com/rundotnet/api/',
        ['method'] = 'POST',
        ['headers'] = {
          ['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
          ['Content-Length'] = #body
        },
        ['source'] = ltn12.source.string(body),
        ['sink'] = ltn12.sink.table(response)
      }
    )

    if res ~= 200 then
      return sendText(msg.chat_id_, msg.id_, _msg('Connection error'))
    end

    local jdat = json.decode(table.concat(response))
    local output = ''

    if jdat.Warnings and type(jdat.Warnings) == 'string' then
      output = output .. '<b>Warnings</b>:\n' .. util.escapeHtml(jdat.Warnings) .. '\n'
    end
    if jdat.Errors and type(jdat.Errors) == 'string' then
      output = output .. '<b>Errors</b>:\n' .. util.escapeHtml(jdat.Errors) .. '\n'
    end
    if jdat.Result and type(jdat.Result) == 'string' then
      output = output .. '<b>Result</b>\n' .. util.escapeHtml(jdat.Result) .. '\n'
    end
    if jdat.Stats and jdat.Stats ~= '' then
      output = output .. '<b>Statistics\n•</b> ' .. jdat.Stats:gsub(', ', '\n<b>•</b> '):gsub('cpu', 'CPU'):gsub('memory', 'Memory'):gsub('absolute', 'Absolute'):gsub(',', '.')
    end

    sendText(msg.chat_id_, msg.id_, output)
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Executes the specified code in the given language and returns the output.'),
    usage = {
      user = {
        'See: https://t.me/tdclibotmanual/45'
        --'<code>!exec [language] [code]</code>',
        --_msg('Executes the specified <code>code</code> in the given <code>language</code> and returns the output.')
      },
    },
    patterns = {
      _config.cmd .. 'exec (%w+) (.*)$'
    },
    run = run
  }

end

