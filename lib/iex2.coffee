{CompositeDisposable} = require 'atom'
path = require 'path'
TermView = require './TermView'
PTY = require 'pty.js'

capitalize = (str)-> str[0].toUpperCase() + str[1..].toLowerCase()



module.exports = Iex2 =
  subscriptions: null
  termViews: []

  activate: (state) ->
    console.log "activate iex2"

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex2:open': => @newIex()

  deactivate: ->
    @subscriptions.dispose()

  createTermView:->
      opts =
        runCommand    : null
        shellArguments: "--init-file /Users/jnorton/.bash_profile"
        titleTemplate : 'iex'
        cursorBlink   : yes
        colors        : {}

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
