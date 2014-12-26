{CompositeDisposable} = require 'atom'
path = require 'path'
TermView = require './TermView'

{SHELL, HOME}=process.env

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()

module.exports = Iex2 =
  subscriptions: null
  termViews: []
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
    console.log "activate iex2"

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex2:open': => @newIex()

  deactivate: ->
    @subscriptions.dispose()

  getColors: ->
    {
      normalBlack, normalRed, normalGreen, normalYellow
      normalBlue, normalPurple, normalCyan, normalWhite
      brightBlack, brightRed, brightGreen, brightYellow
      brightBlue, brightPurple, brightCyan, brightWhite
    } = atom.config.get('iex2.colors')
    [
      normalBlack, normalRed, normalGreen, normalYellow
      normalBlue, normalPurple, normalCyan, normalWhite
      brightBlack, brightRed, brightGreen, brightYellow
      brightBlue, brightPurple, brightCyan, brightWhite
    ]

  createTermView:->
      opts =
        runCommand    : null
        shellArguments: "-c iex"
        titleTemplate : 'iex'
        cursorBlink   : atom.config.get('iex2.cursorBlink')
        colors        : @getColors()

      termView = new TermView opts
      console.log "CREATE"
      termView.on 'remove', @handleRemoveTerm.bind this

      @termViews.push? termView
      termView

  newIex: ->
    console.log "NEW IEX"
    termView = @createTermView()
    pane = atom.workspace.getActivePane()
    item = pane.addItem termView
    pane.activateItem item

  handleRemoveTerm: (termView)->
    @termViews.splice @termViews.indexOf(termView), 1

  #serialize: ->
