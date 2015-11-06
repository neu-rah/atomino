childProc = require 'child_process'
AtominoView = require './atomino-view'
{CompositeDisposable} = require 'atom'
apd = require 'atom-package-dependencies'
apd.install()

module.exports = Atomino =
  atominoView: null
  modalPanel: null
  subscriptions: null
  config:
    options:
      title: "Options"
      description: "Extra parameters to be appended to cosa command line."
      type: "string"
      default: ""
    monitor:
      title: "Monitor port"
      description: "Specify serial monitor port."
      type: "string"
      default: ""
    programmer:
      title: "ISP Programmer port"
      description: "Specify ISP programmer port if any. ex: /dev/ttyUSB0"
      type: "string"
      default: ""
    ARDUINO_DIR:
      title: "Arduino IDE folder"
      description: "leave blank to use cosa default"
      type: "string"
      default: ""
    COSA_DIR:
      title: "Cosa folder"
      description: "Cosa instalation folder, leave blank for default cosa folder."
      type: "string"
      default: ""
    cosaBoard:
      title: "Cosa board"
      description: "Specify target board."
      type: "string"
      default: ""
      enum: [
        "adafruit-atmega32u4-cat  Cosa AdaFruit (ATmega32U4/Caterina)",
        "adafruit-atmega32u4      Cosa AdaFruit (ATmega32U4/LUFA+)",
        "atmega328-8              Cosa Breadboard (ATmega328, 8 MHz internal clock)",
        "attiny84-8               Cosa Breadboard (ATtiny84, 8 MHz internal clock)",
        "attiny85-8               Cosa Breadboard (ATtiny85, 8 MHz internal clock)",
        "attiny861-8              Cosa Breadboard (ATtiny861, 8 MHz internal clock)",
        "diecimila                Cosa Arduino Diecimila (ATmega168/BOOT_168)",
        "duemilanove              Cosa Arduino Duemilanove (ATmega328/BOOT_168)",
        "iboard                   Cosa ITEAD Studio IBoard (ATmega328/BOOT_168)",
        "leonardo                 Cosa Arduino Leonardo (ATmega32U4/Caterina)",
        "lilypad                  Cosa LilyPad Arduino (ATmega328/BOOT_168, 8 MHz)",
        "lilypad-usb              Cosa LilyPad Arduino USB (ATmega32U4/Caterina, 8 MHz)",
        "mega1280                 Cosa Arduino Mega (ATmega1280/BOOT_168)",
        "mega2560                 Cosa Arduino Mega (ATmega2560/STK500v2)",
        "microduino-core32u4      Cosa Microduino-Core32u4 (ATmega32U4/Caterina)",
        "microduino-core          Cosa Microduino-Core (ATmega328/Optiboot)",
        "microduino-core-plus     Cosa Microduino-Core+ (ATmega644P/Optiboot)",
        "micro                    Cosa Arduino Micro (ATmega32U4/Caterina)",
        "mighty                   Cosa Breadboard (ATmega1284P/BOOT_1284P)",
        "mighty-opt               Cosa Breadboard (ATmega1284P/Optiboot)",
        "miniwireless             Cosa Anarduino MiniWireless (ATmega328/BOOT_168)",
        "moteino-mega             Cosa LowPowerLab Moteino Mega (ATmega1284P/DualOptiboot)",
        "moteino                  Cosa LowPowerLab Moteino (ATmega328/DualOptiboot)",
        "nano                     Cosa Arduino Nano (ATmega328/BOOT_168)",
        "pinoccio                 Cosa Pinoccio Scout (ATmega256RFR2/STK500v2)",
        "pro-micro-8              Cosa Arduino Pro Micro (ATmega32U4/Caterina, 3.3V, 8 MHz)",
        "pro-micro                Cosa Arduino Pro Micro (ATmega32U4/Caterina)",
        "pro-mini-8               Cosa Arduino Pro Mini (ATmega328/BOOT_168, 3.3V, 8 MHz)",
        "pro-mini                 Cosa Arduino Pro Mini (ATmega328/BOOT_168)",
        "uno                      Cosa Arduino Uno (ATmega328/Optiboot)",
        "wildfire                 Cosa Wicked Device WireFire (ATmega1284P/Optiboot)",
        ""
      ]

  activate: (state) ->
    console.log "Atomino:activate"
    @atominoView = new AtominoView(state.atominoViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atominoView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:compile': => @compile()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:updateBoards': => @updateBoards()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:cosaBoards': => @cosaBoards()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:cosaConfig': => @cosaConfig()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:cosaClean': => @cosaClean()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:cosaReset': => @cosaReset()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:cosaSize': => @cosaSize()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:monitor': => @monitor()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:settings': => @settings()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atomino:debug': => @atomino_debug()

  consumeConsolePanel: (@consolePanel) ->
  log: (message) ->
    @consolePanel.log(message)

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'atomino'

    @toolBar.addButton
      icon: 'circuit-board'
      callback: 'atomino:compile'
      tooltip: 'Compile and Upload'

    @toolBar.addButton
      icon: 'device-desktop'
      callback: 'terminal-plus:new'
      tooltip: 'Serial monitor'

    button = @toolBar.addButton
      icon: 'gear-a'
      callback: 'atomino:settings'
      tooltip: 'Show Settings'
      iconset: 'ion'

    # Adding spacer
    @toolBar.addSpacer()

    @toolBar.addButton
      icon: 'sync'
      callback: 'atomino:cosaReset'
      tooltip: 'Reset board'

    @toolBar.addButton
      icon: 'dashboard'
      callback: 'atomino:cosaSize'
      tooltip: 'Show the size of the compiled output (relative to resources, if you have a patched avr-size).'

    @toolBar.addButton
      icon: 'trashcan'
      callback: 'atomino:cosaClean'
      tooltip: 'Remove all generated files'

    # Adding spacer
    @toolBar.addSpacer()

    @toolBar.addButton
      icon: 'list-unordered'
      callback: 'atomino:cosaBoards'
      tooltip: 'List supported boards'

    @toolBar.addButton
      icon: 'checklist'
      callback: 'atomino:cosaConfig'
      tooltip: 'Show board configuration'

  deactivate: ->
    @toolBar?.removeItems()
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

  settings:-> atom.workspace.open("atom://config/packages/atomino")

  shellRun: (cmd,fn) ->
    showOut= (p) -> (err, stdout, stderr) ->
      p.error ""+err if err
      p.log ""+stdout
      p.warn ""+stderr if stderr
      return err
    childProc.exec cmd,if fn then fn else showOut @consolePanel

  mkParam: (text,value)->
    return (if value then " "+text+value else "")

  mkExport: (name)->
    cfg=atom.config.get("atomino")
    return (if cfg[name] then " "+name+"="+cfg[name]+";export "+name+";" else "")

  setBoards: (err,stdout,stderr) ->
    console.log "initBoards:",stdout.split("\t").join("+"),stderr
    boards=(stdout+"").split("\n");
    console.log boards.length+" boards"
    atom.packages.getActivePackage('atomino').mainModule.config.cosaBoard= {type:'string',default:'',enum:boards}

  cosa: (src,board,params) ->
    exports=@mkExport "ARDUINO_DIR" + @mkExport "COSA_DIR"
    cmdline=@shellRun "cd "+src+";"+exports+" cosa "+board+" "+params
    @consolePanel.notice cmdline
    return cmdline

  updateBoards: ->
    return @shellRun "cd "+atom.project.getPaths()[0]+"; cosa boards",@setBoards

  cosaCmd: (cmd) ->
    @consolePanel.notice "Cosa command: "+cmd
    path=atom.project.getPaths()[0]
    cfg=atom.config.get("atomino")
    board=cfg.cosaBoard.split("Cosa")
    @consolePanel.notice "Selected board: "+cfg.cosaBoard
    @cosa path, board[0].trim(), " "+cmd

  cosaBoards: -> @cosaCmd "boards"
  cosaConfig: -> @cosaCmd "config"
  cosaClean: -> @cosaCmd "clean"
  cosaReset: -> @cosaCmd "reset"
  cosaSize: -> @cosaCmd "size"

  atomino_debug: ->
    console.log @consolePanel
    @consolePanel.log("LOG")
    @consolePanel.error("ERROR")
    @consolePanel.warn("WARN")
    @consolePanel.notice("NOTICE")
    @consolePanel.debug("DEBUG")
    #atom.packages.getActivePackage('atomino').mainModule.config.test={type:'string',default:'ok',enum:['ok','cancel']}

  compile: ->
    path=atom.project.getPaths()[0]
    @consolePanel.notice 'Cosa compiling:'+path
    cfg=atom.config.get("atomino")
    board=cfg.cosaBoard.split("Cosa")
    @cosa path, board[0].trim(), (if cfg.programmer then (@mkParam "ispload ISP_PORT=",cfg.programmer) else "upload") + cfg.options
