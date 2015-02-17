require! {
  'Router'
  'audio/effects'
  'audio/music-manager'
  'game/area/background'
  'game/load'
  'game/pauser'
  'lib/channels'
  'loader/LoaderView'
  'logger'
  'settings'
  'ui/Bar'
  'ui/MainMenuView'
  'ui/alert'
  'ui/overlay-views'
  'user'
}

const level-types = <[cutscene area]>
$overlay = $ '#overlay'
$settings-button = $ '#bar .settings-button'

module.exports = class App
  states:
    init: {leave: <[initialized]>}
    menus: {enter: <[cleanupPlaying showActiveMenu cleanupPlayingRemains]>, leave: <[hideActiveMenu]>}
    menus-overlay: {enter: <[showOverlay cleanupPlaying]>, leave: <[hideOverlay]>}
    loading: {enter: <[cleanupPlaying startLoader]>}
    playing: {enter: <[startEventLoop]>, leave: <[stopEventLoop]>}
    paused: {enter: <[showOverlay]>, leave: <[hideOverlay]>}
    editing: {}
    editing-paused: {enter: <[showOverlay]>, leave: <[hideOverlay]>}

  transitions:
    init:
      init: \menus
      load: \loading
      pause: \menusOverlay

    menus:
      pause: \menusOverlay
      load: \loading

    menusOverlay:
      resume: \menus

    loading:
      quit:
        enter-state: \menus
        callbacks: <[cancelLoader]>
      start: \playing

    playing:
      load: \loading
      pause: \paused
      edit:
        enter-state: \editing
        callbacks: <[showEditor]>
      quit: \menus

    paused:
      resume: \playing
      quit: \menus

    editing:
      edit-finished:
        enter-state: \playing
        callbacks: <[hideEditor]>
      quit: \menus
      load: \loading
      pause: \editingPaused

    editing-paused:
      resume: \editing
      quit: \menus

  ->
    _.extend this, Backbone.StateMachine, Backbone.Events
    @start-state-machine!
    @on 'transition' (leave, enter) -> console.log "[transition] #leave -> #enter"

    Promise
      .all [
        effects.load!
        user.fetch! .then (user-data) -> Promise.all [
          user.recent-games!
          logger.setup false, user-data?.id
        ]
      ]
      .spread (_, [save-games])~>
        @save-games = save-games
        @router = new Router app: this
        Backbone.history.start root: window.location.pathname
      .catch (e) ->
        console.error e
        channels.alert.publish msg: 'Error loading: ' + e.message
        throw e

  show-menu: (menu = 'main') ->
    @switch-menu menu

    console.log @current-state
    switch @current-state
    | \init => @trigger-async \init
    | \menusOverlay => @trigger-async \resume
    | otherwise => @trigger-async \quit

  load: (type, path) ->
    p = if @overlay-active!
      @trigger-async \resume
    else if @current-state is \loading
      @trigger-async \quit
    else Promise.delay 0

    p.finally ~>
      @trigger-async \load, {type, path} unless @_active-play === {type, path}

  error: (msg) ->
    window.alert msg

  switch-menu: (name) -> @_active-menu = name

  initialized: ~>
    $overlay-views = $ '#overlay-views'
    @bar = new Bar el: ($ '#bar'), views: overlay-views {settings, user, $overlay-views, save-games: @save-games}
      ..show!
      ..on \dismiss, ~> @dismiss-app-overlay!

    # Hide the loader and start up the game.
    $ \.loader .hide-dialogue!
    @_menus = {
      main: new MainMenuView app: this, collection: @save-games, el: $ '#main-menu'
    }

    channels.game-commands.filter ( .command is \edit ) .subscribe ~> @edit!

    return Promise.delay 400

  show-app-overlay: (name = 'settings') ->
    @switch-overlay name
    switch @current-state
    | \init, \menus, \playing, \editing => @trigger-async \pause
    | \loading => @trigger-async \quit .then ~> @show-app-overlay name
    | \menusOverlay, \paused, \editing-paused => # Already there, do nothing

  dismiss-app-overlay: ->
    if @_active-play
      {type, path} = @_active-play
      window.location.hash = "#/playing"
    else
      window.location.hash = '#/menu'

  switch-overlay: (name = @_active-overlay) ->
    console.log "switch overlay #{@_active-overlay} -> #name"
    @_active-overlay = name
    if @overlay-active!
      @bar.activate name

  overlay-active: -> @current-state in <[menusOverlay paused editingPaused]>

  edit: ->
    if @_level and @_level.is-editable! and @current-state is \playing
      @trigger-async 'edit'

  cleanup-playing: ->
    @_active-play = null
    if @_level
      @_level = null
      that.cleanup!

  cleanup-playing-remains: ->
    # Get rid of the last few bits of a playing session. We leave backgrounds and
    # music in place in a normal cleanup in case they are used again.
    background.clear!
    music-manager.start-track 'none'

  start-loader: ({type, path}) !->
    unless type in level-types then throw new Error "Bad level type #type!"
    @show-loader!
    @_active-play = {type, path}
    @_current-loader = load[type] path, this
      .cancellable!
      .then (level) ~>
        @_level = level
        @trigger \start
        level.start!
      .catch Promise.CancellationError, ->
      .catch (e) ~>
        console.error e
        channels.alert.publish msg: e.message
        window.location.href = '#/menu'
      .finally ~>
        @_current-loader = null
        @hide-loader!

  cancel-loader: ~>
    if @_current-loader then @_current-loader.cancel!

  show-loader: ~>
    @loader-view ?= new LoaderView el: $ '.loader'
    @loader-view.show!

  hide-loader: ~>
    if @loader-view then @loader-view.hide!

  show-active-menu: ->
    @_menus[@_active-menu]?.$el.make-only-shown-dialogue!

  hide-active-menu: ->
    @_menus[@_active-menu]?.$el.hide-dialogue!
    @_active-menu = null

  show-overlay: ->
    $overlay.add-class 'active'
    $settings-button.add-class 'active'
    @switch-overlay!

  hide-overlay: ->
    @switch-overlay \none
    $settings-button.remove-class 'active'
    $overlay.remove-class 'active' .add-class 'inactive'
    <~ $overlay.one prefixed.animation-end
    $overlay.remove-class 'inactive'

  start-event-loop: ->
    channels.game-commands.publish command: \force-resume

  stop-event-loop: ->
    channels.game-commands.publish command: \force-pause

  show-editor: ->
    if @_level and @_level.is-editable!
      debugger
      @_level.edit!
      @_level.once 'stop-editor' ~> @trigger \editFinished

  hide-editor: ->
    console.log 'hide-editor'
    if @_level then @_level.hide-editor!
