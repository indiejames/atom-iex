util        = require 'util'
path        = require 'path'
os          = require 'os'
fs          = require 'fs-plus'
uuid        = require 'uuid'

Terminal    = require 'atom-iex-term.js'

keypather   = do require 'keypather'

{Task, CompositeDisposable} = require 'atom'
{$, View, ScrollView} = require 'atom-space-pen-views'

uuids = []

last = (str)-> str[str.length-1]

generateUUID = ()->
  new_id = uuid.v1().substring(0,4)
  while new_id in uuids
    new_id = uuid.v1().substring(0,4)
  uuids.push new_id
  new_id

getMixFilePath = ()->
  mixPath = null
  for projectPath in atom.project.getPaths()
    do (projectPath) ->
      if projectPath && fs.existsSync(path.join(projectPath, 'mix.exs'))
        mixPath = path.join(projectPath, 'mix.exs')
        return
  mixPath


renderTemplate = (template, data)->
  vars = Object.keys data
  vars.reduce (_template, key)->
    _template.split(///\{\{\s*#{key}\s*\}\}///)
      .join data[key]
  , template.toString()

class TermView extends View

  tabindex: -1

  @content: ->
    @div class: 'iex', click: 'click'

  constructor: (@opts={})->
    opts.shell = process.env.SHELL or 'bash'
    opts.shellArguments or= ''

    editorPath = keypather.get atom, 'workspace.getEditorViews[0].getEditor().getPath()'
    opts.cwd = opts.cwd or atom.project.getPaths()[0] or editorPath or process.env.HOME
    super

  forkPtyProcess: (args=[])->
    processPath = require.resolve './pty'
    projectPath = atom.project.getPaths()[0] ? '~'
    Task.once processPath, fs.absolute(projectPath), args

  initialize: (@state)->
    iexSrcPath = atom.packages.resolvePackagePath("iex") + "/elixir_src/iex.exs"
    {cols, rows} = @getDimensions()
    {cwd, shell, shellArguments, runCommand, colors, cursorBlink, scrollback} = @opts
    new_id = generateUUID()
    iexPath = 'iex'
    args = ["-l", "-c", iexPath + " --sname IEX-" + new_id + " -r " + iexSrcPath]
    mixPath = getMixFilePath()
    # assume mix file is at top level
    if mixPath
      file_str = fs.readFileSync(mixPath, {"encoding": "utf-8"})
      phoenix_str = ""
      if file_str.match(/applications.*:phoenix/g)
        phoenix_str = " phoenix.server"
        console.log phoenix_str
      args = ["-l", "-c", iexPath + " --sname IEX-" + new_id + " -r " + iexSrcPath + " -S mix" + phoenix_str]

    @term = term = new Terminal {
      useStyle: no
      screenKeys: no
      colors: colorsArray
      cursorBlink, scrollback, cols, rows
    }

    @ptyProcess = @forkPtyProcess args
    @ptyProcess.on 'iex:data', (data) => @term.write data
    @ptyProcess.on 'iex:exit', (data) => @destroy()

    colorsArray = (colorCode for colorName, colorCode of colors)

    term.end = => @destroy()

    term.on "copy", (text)=> @copy(text)

    term.on "data", (data)=> @input data
    term.open this.get(0)

    @input "#{runCommand}#{os.EOL}" if runCommand
    term.focus()
    @attachEvents()
    @resizeToPane()


  focus: ->
    @resizeToPane()
    @focusTerm()
    #super

  focusTerm: ->
    @term.element.focus()
    @term.focus()


  onActivePaneItemChanged: (activeItem) =>
    console.log "Checking to see if this pane selected"
    console.log activeItem
    console.log activeItem.items.length
    console.log this
    if (activeItem && activeItem.items.length == 1 && activeItem.items[0] == this)
      console.log "Focusing term"
      @focus()

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
    @resizeToPane = @resizeToPane.bind this
    @attachResizeEvents()
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add '.iex', 'iex:paste': => @paste()
    @subscriptions.add atom.commands.add '.iex', 'iex:copy': => @copy()
    @subscriptions.add atom.workspace.onDidChangeActivePane(@onActivePaneItemChanged)
    #atom.workspace.onDidChangeActivePaneItem (item)=> @onActivePaneItemChanged(item)

  click: (evt, element) ->
    @focus()

  paste: ->
    @input atom.clipboard.read()

  copy: ->
    if @term._selected  # term.js visual mode selections
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

  resizeToPane: ->
    {cols, rows} = @getDimensions()
    return unless cols > 0 and rows > 0
    return unless @term
    return if @term.rows is rows and @term.cols is cols

    @resize cols, rows
    @term.resize cols, rows
    #atom.workspaceView.getActivePaneView().css overflow: 'auto'

  getDimensions: ->
    fakeCol = $("<span id='colSize'>m</span>").css visibility: 'hidden'
    if @term
      @find('.terminal').append fakeCol
      fakeCol = @find(".terminal span#colSize")
      cols = Math.floor (@width() / fakeCol.width()) or 9
      #cols = Math.floor (@width() / 10)  or 9
      rows = (Math.floor (@height() / fakeCol.height()) - 2) or 16
      #rows = Math.floor (@height() / 14)  or 16
      fakeCol.remove()
    else
      cols = Math.floor @width() / 7
      rows = Math.floor @height() / 14

    {cols, rows}

  activate: ->
    @focus

  deactivate: ->
    @subscriptions.dispose()

  destroy: ->
    console.log "Destroying TermView"
    @input "\nSystem.halt\n\n"
    console.log "System halted"
    # this is cheesy and a race condition, but apparently I need a delay
    # before continuing so the IEx system can halt
    # FIXME - race condition
    count = 10000000
    while count -= 1
      ""

    @detachResizeEvents()

    @ptyProcess.send("exit")
    @ptyProcess.terminate()
    @term.destroy()
    parentPane = atom.workspace.getActivePane()
    if parentPane.activeItem is this
      parentPane.removeItem parentPane.activeItem
    @detach()

module.exports = TermView
