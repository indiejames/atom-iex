# from atom/terminal to reduce cpu usage
console.log "PTY0"
pty = require 'pty.js'
console.log "REQUIRED PTY.JS"

module.exports = (ptyCwd, args) ->
  callback = @async()
  args = ["-c", "iex -S mix"]
  console.log("ARGS...")
  console.log(args)
  if process.platform is 'win32'
    shell = 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe'

    # TODO: Remove this swapping once atom/pty.js#47 lands
    cols = 30
    rows = 80
  else
    console.log "PTY2"
    shell = process.env.SHELL
    cols = 80
    rows = 30
    console.log "PTY3"
  console.log "SHELL..."
  console.log shell
  ptyProcess = pty.fork shell, args,
    name: 'xterm-256color'
    cols: cols
    rows: rows
    cwd: ptyCwd
    env: process.env

  ptyProcess.on 'data', (data) -> emit('iex:data', data)
  ptyProcess.on 'exit', ->
    emit('iex:exit')
    callback()

  process.on 'message', ({event, cols, rows, text}={}) ->
    switch event
      when 'resize' then ptyProcess.resize(cols, rows)
      when 'input' then ptyProcess.write(text)
