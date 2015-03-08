# from atom/terminal to reduce cpu usage
#pty = require 'pty.js'
pty = require 'child_pty'

module.exports = (ptyCwd, args) ->
  callback = @async()
  shell = process.env.SHELL
  cols = 80
  rows = 30

  ptyProcess = pty.spawn shell, args,
    name: 'xterm-256color'
    cols: cols
    rows: rows
    cwd: ptyCwd

  ptyProcess.stdout.on 'data', (data) ->
    sdata = data.toString("utf8")
    emit('iex:data', sdata)
  ptyProcess.on 'exit', ->
    emit('iex:exit')
    callback()

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.stdout.resize({columns: cols, rows: rows})
      when 'input' then ptyProcess.stdin.write(text)
