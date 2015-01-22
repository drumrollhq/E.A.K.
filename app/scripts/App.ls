require! {
  'settings'
  'Router'
  'audio/effects'
  'game/Game'
  'game/load'
  'lib/channels'
  'logger'
  'ui/alert'
  'ui/Bar'
  'ui/overlay-views'
  'user'
}

const level-types = <[cutscene area]>

module.exports = class App
  states:
    init: {leave: <[initialized]>}
    menus: {enter: <[cleanupPlaying showActiveMenu]>, leave: <[hideActiveMenu]>}
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
        @game = new Game false
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
    @game = new Game false
    @_menus = {
      main: $ '#main-menu'
    }

    return Promise.delay 400

  cleanup-playing: ->
    if @_level
      @_level = null
      that.cleanup!

  start-loader: ({type, path}) !->
    unless type in level-types then throw new Error "Bad level type #type!"
    @_current-loader = load[type] path, this
      .cancellable!
      .then (level) ~>
        @_level = level
        @trigger \start
        level.start!
      .catch (e) ~>
        console.error e
        channels.alert.publish msg: e.message
        window.location.href = '#/menu'
      .finally ~> @_current-loader = null

  cancel-loader: ~>
    if @_current-loader then @_current-loader.cancel!

  show-active-menu: ->
    @_menus[@_active-menu]?.make-only-shown-dialogue!

  hide-active-menu: ->
    @_menus[@_active-menu]?.hide-dialogue!

  hide-overlay: ->
  show-overlay: ->
  start-event-loop: ->
  stop-event-loop: ->
