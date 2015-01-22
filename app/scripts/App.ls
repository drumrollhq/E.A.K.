require! {
  'Router'
  'audio/effects'
  'audio/music-manager'
  'game/area/background'
  'game/load'
  'lib/channels'
  'loader/LoaderView'
  'logger'
  'settings'
  'ui/Bar'
  'ui/alert'
  'ui/overlay-views'
  'user'
}

const level-types = <[cutscene area]>

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
      edit: \editing
      quit: \menus

    paused:
      resume: \playing
      quit: \menus

    editing:
      edit-finished: \playing
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
        user.fetch! .then (user) -> logger.setup false, user.id
      ]
      .then ~>
        @router = new Router app: this
        Backbone.history.start root: window.location.pathname
      .catch (e) ->
        console.error e
        throw e
        channels.alert.publish msg: 'Error loading: ' + e.message

  show-menu: (menu = 'main') ->
    @switch-menu menu

    switch @current-state
    | \init => @trigger-async \init
    | \menusOverlay => @trigger-async \pause
    | otherwise => @trigger-async \quit

  load: (type, path) ->
    p = if @current-state in <[menusOverlay paused editingPaused]>
      @trigger-async \resume
    else if @current-state is \loading
      @trigger-async \quit
    else Promise.delay 0

    p.finally ~> @trigger-async \load, {type, path}

  switch-menu: (name) -> @_active-menu = name

  initialized: ~>
    $overlay-views = $ '#overlay-views'
    @bar = new Bar el: ($ '#bar'), views: overlay-views {settings, user, $overlay-views}
    @bar.show!

    # Hide the loader and start up the game.
    $ \.loader .hide-dialogue!
    @_menus = {
      main: $ '#main-menu'
    }

    return Promise.delay 400

  cleanup-playing: ->
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
    @_menus[@_active-menu]?.make-only-shown-dialogue!

  hide-active-menu: ->
    @_menus[@_active-menu]?.hide-dialogue!
    @_active-menu = null

  hide-overlay: ->
  show-overlay: ->
  start-event-loop: ->
  stop-event-loop: ->
