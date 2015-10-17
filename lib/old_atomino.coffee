childProc = require 'child_process'
AtominoView = require './atomino-view'
{CompositeDisposable} = require 'atom'
module.exports = Atomino =
  atominoView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    console.log "Atomino:activate",state
    @atominoView = new AtominoView(state.atominoViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atominoView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:compile': => @compile()

  deactivate: ->
    console.log "atomino deactivate"
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atominoView.destroy()

  serialize: ->
    atominoViewState: @atominoView.serialize()

  toggle: ->
    console.log 'Atomino was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  shellRun: (cmd,fn) ->
    showOut= (err, stdout, stderr) ->
      console.log err if err
      console.log stdout
      console.log stderr
      return err
    childProc.exec cmd,if fn then fn else showOut

  cosa: (src,board,params) ->
    return @shellRun "cd "+src+"; cosa "+board+" "+params

  compile: ->
    console.log 'Cosa compiling:'
    @cosa atom.project.getPaths()[0], "atmega328-8", "ispload ISP_PORT=/dev/ttyUSB0"
