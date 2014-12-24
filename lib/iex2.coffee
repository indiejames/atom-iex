{CompositeDisposable} = require 'atom'

module.exports = Iex2 =
  subscriptions: null

  activate: (state) ->
    console.log "activate iex2"

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'iex2:open': => @newIex()

  deactivate: ->
    @subscriptions.dispose()

  newIex: ->
    console.log "NEW IEX"

  #serialize: ->
