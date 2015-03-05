# from atom/terminal to reduce cpu usage
#pty = require 'pty.js'
pty = require 'child_pty'

module.exports = (ptyCwd, args) ->
  callback = @async()
  if process.platform is 'win32'
    shell = 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe'

    # TODO: Remove this swapping once atom/pty.js#47 lands
    cols = 30
    rows = 80
  else
    shell = process.env.SHELL
    cols = 80
    rows = 30
  # ptyProcess = pty.spawn shell, args,
  #   name: 'xterm-256color'
  #   cols: cols
  #   rows: rows
  #   cwd: ptyCwd
  #   env: process.atom-space-pen-views
  ptyProcess = pty.spawn shell, args,
    name: 'xterm-256color'
    cols: cols
    rows: rows
    cwd: ptyCwd
    #env: process.atom-space-pen-views

  ptyProcess.stdout.on 'data', (data) ->
    sdata = data.toString("ascii")
    emit('iex:data', sdata)
  ptyProcess.on 'exit', ->
    emit('iex:exit')
    callback()

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.stdout.resize({columns: cols, rows: rows})
      when 'input' then ptyProcess.stdin.write(text)
