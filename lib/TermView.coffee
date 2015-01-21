util       = require 'util'
path       = require 'path'
os         = require 'os'
fs         = require 'fs-plus'

debounce   = require 'debounce'
Terminal   = require 'atom-term.js'

keypather  = do require 'keypather'

{Task, CompositeDisposable} = require 'atom'
{$, View, ScrollView} = require 'atom-space-pen-views'

last = (str)-> str[str.length-1]

renderTemplate = (template, data)->
  vars = Object.keys data
  vars.reduce (_template, key)->
    _template.split(///\{\{\s*#{key}\s*\}\}///)
      .join data[key]
  , template.toString()

class TermView extends View

  @content: ->
    @div class: 'iex'

  constructor: (@opts={})->
    opts.shell = process.env.SHELL or 'bash'
    opts.shellArguments or= ''

    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = opts.cwd or atom.project.getPath() or editorPath or process.env.HOME
    super

  forkPtyProcess: (args=[])->
    processPath = require.resolve './pty'
    projectPath = atom.project.getPath() ? '~'
    Task.once processPath, fs.absolute(projectPath), args

  initialize: (@state)->
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, runCommand, colors, cursorBlink, scrollback} = @opts
    args = ["-c", "iex"]
    projectPath = atom.project.getPath()
    fileExists = fs.existsSync(path.join(projectPath, 'mix.exs'))
    if fileExists
      args = ["-c", "iex -S mix"]
    @ptyProcess = @forkPtyProcess args
    @ptyProcess.on 'iex:data', (data) => @term.write data
    @ptyProcess.on 'iex:exit', (data) => @destroy()

    colorsArray = (colorCode for colorName, colorCode of colors)
    @term = term = new Terminal {
      useStyle: no
      screenKeys: no
      colors: colorsArray
      cursorBlink, scrollback, cols, rows
    }

    term.end = => @destroy()

    term.on "copy", (text)=> @copy(text)

    term.on "data", (data)=> @input data
    term.open this.get(0)

    @input "#{runCommand}#{os.EOL}" if runCommand
    term.focus()
    @attachEvents()
    @resizeToPane()

  input: (data) ->
    @ptyProcess.send event: 'input', text: data

  resize: (cols, rows) ->
    @ptyProcess.send {event: 'resize', rows, cols}

  titleVars: ->
    bashName: last @opts.shell.split '/'
    hostName: os.hostname()
    platform: process.platform
    home    : process.env.HOME

  getTitle: ->
    @vars = @titleVars()
    titleTemplate = @opts.titleTemplate or "({{ bashName }})"
    renderTemplate titleTemplate, @vars

  attachEvents: ->
    console.log "ATTACHING EVENTS"
    @resizeToPane = @resizeToPane.bind this
    @attachResizeEvents()
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add '.iex', 'iex:paste': => @paste()
    @subscriptions.add atom.commands.add 'iex', 'iex:copy': => @copy()
    #@command "iex:paste", => @paste()
    #@command "iex:copy", => @copy()
    console.log "DONE ATTACHING EVENTS"

  paste: ->
    @input atom.clipboard.read()

  # copy: (text) ->
  #   console.log "COPYING"
  #   console.log text
  #   atom.clipboard.write(text, {})

  copy: ->
    if  @term._selected  # term.js visual mode selections
      textarea = @term.getCopyTextarea()
      text = @term.grabText(
        @term._selected.x1, @term._selected.x2,
        @term._selected.y1, @term._selected.y2)
    else # fallback to DOM-based selections
      text = @term.context.getSelection().toString()
      rawText = @term.context.getSelection().toString()
      rawLines = rawText.split(/\r?\n/g)
      lines = rawLines.map (line) ->
        line.replace(/\s/g, " ").trimRight()
      text = lines.join("\n")
    atom.clipboard.write text

  attachResizeEvents: ->
    setTimeout (=>  @resizeToPane()), 10
    @on 'focus', @focus
    $(window).on 'resize', => @resizeToPane()

  detachResizeEvents: ->
    @off 'focus', @focus
    $(window).off 'resize'

  focus: ->
    @resizeToPane()
    @focusTerm()
    super

  focusTerm: ->
    @term.element.focus()
    @term.focus()

  resizeToPane: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @term
    return if @term.rows is rows and @term.cols is cols

    @resize cols, rows
    @term.resize cols, rows
    atom.workspaceView.getActivePaneView().css overflow: 'visible'

  getDimensions: ->
    fakeCol = $("<span id='colSize'>&nbsp;</span>").css visibility: 'hidden'
    if @term
      @find('.terminal').append fakeCol
      fakeCol = @find(".terminal span#colSize")
      cols = Math.floor (@width() / fakeCol.width()) or 9
      rows = Math.floor (@height() / fakeCol.height()) or 16
      fakeCol.remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    {cols, rows}

  deactivate: ->
    @subscriptions.dispose()

  destroy: ->
    @detachResizeEvents()
    @ptyProcess.terminate()
    @term.destroy()
    parentPane = atom.workspace.getActivePane()
    if parentPane.activeItem is this
      parentPane.removeItem parentPane.activeItem
    @detach()

module.exports = TermView
