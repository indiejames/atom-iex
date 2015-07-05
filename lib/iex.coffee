{CompositeDisposable, Point} = require 'atom'
path = require 'path'
TermView = require './TermView'
os = require 'os'

{SHELL, HOME}=process.env

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

paneChanged = (pane)-> console.log("Pane changed")

module.exports = Iex =
  subscriptions: null
  termViews: []
  focusedTerminal: off
  config:
    scrollback:
      type: 'integer'
      default: 1000
    cursorBlink:
      type: 'boolean'
      default: yes
    openPanesInSameSplit:
      type: 'boolean'
      default: no
    colors:
      type: 'object'
      properties:
        normalBlack :
          type: 'string'
          default: '#2e3436'
        normalRed   :
          type: 'string'
          default: '#cc0000'
        normalGreen :
          type: 'string'
          default: '#4e9a06'
        normalYellow:
          type: 'string'
          default: '#c4a000'
        normalBlue  :
          type: 'string'
          default: '#3465a4'
        normalPurple:
          type: 'string'
          default: '#75507b'
        normalCyan  :
          type: 'string'
          default: '#06989a'
        normalWhite :
          type: 'string'
          default: '#d3d7cf'
        brightBlack :
          type: 'string'
          default: '#555753'
        brightRed   :
          type: 'string'
          default: '#ef2929'
        brightGreen :
          type: 'string'
          default: '#8ae234'
        brightYellow:
          type: 'string'
          default: '#fce94f'
        brightBlue  :
          type: 'string'
          default: '#729fcf'
        brightPurple:
          type: 'string'
          default: '#ad7fa8'
        brightCyan  :
          type: 'string'
          default: '#34e2e2'
        brightWhite :
          type: 'string'
          default: '#eeeeec'

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    ['up', 'right', 'down', 'left'].forEach (direction)=>
        @subscriptions.add atom.commands.add 'atom-workspace',"iex:open-split-#{direction}", @splitTerm.bind(this, direction)
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex:open': => @newIEx()
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex:pipe': => @pipeIEx()
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex:help': => @printHelp()
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex:run-all-tests': => @runAllTests()
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex:run-tests': => @runTests()
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex:run-test': => @runTest()
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex:reset': => @resetIEx()
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex:pretty-print': => @prettyPrint()
    @subscriptions.add atom.workspace.onDidChangeActivePane(paneChanged)
    console.log "activate iex"

  deactivate: ->
    @termViews.forEach (view)-> view.deactivate()
    @subscriptions.dispose()

  getColors: ->
    {
      normalBlack, normalRed, normalGreen, normalYellow
      normalBlue, normalPurple, normalCyan, normalWhite
      brightBlack, brightRed, brightGreen, brightYellow
      brightBlue, brightPurple, brightCyan, brightWhite
    } = atom.config.get('iex.colors')
    [
      normalBlack, normalRed, normalGreen, normalYellow
      normalBlue, normalPurple, normalCyan, normalWhite
      brightBlack, brightRed, brightGreen, brightYellow
      brightBlue, brightPurple, brightCyan, brightWhite
    ]

  createTermView:->

    opts =
      runCommand    : null
      shellArguments: null
      titleTemplate : 'IEx'
      cursorBlink   : atom.config.get('iex.cursorBlink')
      colors        : @getColors()

    termView = new TermView opts
    termView.on 'remove', @handleRemoveTerm.bind this
    termView.on "click", => @focusedTerminal = termView
    @focusedTerminal = termView

    @termViews.push? termView
    termView

  runCommand: (cmd) ->
    if @focusedTerminal
      if Array.isArray @focusedTerminal
        [pane, item] = @focusedTerminal
        pane.activateItem item
      else
        item = @focusedTerminal

      item.term.send(cmd)
      item.term.focus()

  resetIEx: ->
    text = 'AtomIEx.reset\n'
    @runCommand(text)

  runAllTests: ->
    text = "AtomIEx.run_all_tests\n"
    @runCommand(text)

  runTests: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      path = editor.getBuffer().file.path
      text = "AtomIEx.run_test(\""
      text = text.concat(path).concat("\")\n")
      @runCommand(text)

  runTest: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      path = editor.getBuffer().file.path
      line_num = editor.getCursorBufferPosition().toArray()[0] + 1
      text = "AtomIEx.run_test(\""
      text = text.concat(path).concat("\",").concat(line_num).concat(")\n")
      @runCommand(text)

  printHelp: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      cursorPosition = editor.getCursorBufferPosition()
      [row, col] = cursorPosition.toArray()
      begRegex = new RegExp("[\\(,\\s]")
      endRegex = new RegExp(".*?[\\(,\\s\.]")
      endRange = [new Point(row, col + 1), new Point(row, col + 10000)]
      begRange = [new Point(row, 0), new Point(row, col)]
      tailIndex = -1
      headIndex = -1

      editor.scanInBufferRange(endRegex, endRange,
        (match, matchText, range, stop, replace) ->
          tailIndex = match.match.index + match.match[0].length - 1
      )

      editor.backwardsScanInBufferRange(begRegex, begRange,
        (match, matchText, range, stop, replace) ->
          headIndex = match.match.index
      )

      text = editor.getText().substring(headIndex, tailIndex)
      @runCommand("h " + text + "\n")

  prettyPrint: ->
    @runCommand("IO.puts(v(-1))\n")

  splitTerm: (direction)->
      openPanesInSameSplit = atom.config.get 'iex.openPanesInSameSplit'
      termView = @createTermView()
      termView.on "click", => @focusedTerminal = termView
      direction = capitalize direction

      splitter = =>
        pane = activePane["split#{direction}"] items: [termView]
        activePane.termSplits[direction] = pane
        @focusedTerminal = [pane, pane.items[0]]

      activePane = atom.workspace.getActivePane()
      activePane.termSplits or= {}
      if openPanesInSameSplit
        if activePane.termSplits[direction] and activePane.termSplits[direction].items.length > 0
          pane = activePane.termSplits[direction]
          item = pane.addItem termView
          pane.activateItem item
          @focusedTerminal = [pane, item]
        else
          splitter()
      else
        splitter()

  newIEx: ->
    termView = @createTermView()
    pane = atom.workspace.getActivePane()
    item = pane.addItem termView
    pane.activateItem item

  pipeIEx: ->
    editor = atom.workspace.getActiveTextEditor()
    if editor
      action = 'selection'
      stream = switch action
        when 'path'
          editor.getBuffer().file.path
        when 'selection'
          editor.getSelectedText()

      if stream and @focusedTerminal
        if Array.isArray @focusedTerminal
          [pane, item] = @focusedTerminal
          pane.activateItem item
        else
          item = @focusedTerminal

        text = stream.trim().concat("\n")
        item.term.send(text)
        item.term.focus()

  handleRemoveTerm: (termView)->
    @termViews.splice @termViews.indexOf(termView), 1
