require! {
  'settings'
  'Router'
  'audio/effects'
  'game/Game'
  'lib/channels'
  'logger'
  'ui/Bar'
  'ui/overlay-views'
  'user'
}

module.exports = class App
  states:
    init: {leave: <[initialized]>}
    menus: {enter: <[cleanupPlaying showActiveMenu]>, leave: <[hideActiveMenu]>}
    menus-overlay: {enter: <[showOverlay cleanupPlaying]>, leave: <[hideOverlay]>}
    loading: {enter: <[cleanupPlaying]>}
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
      quit: \menus
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
    | \init => @trigger \init
    | \menusOverlay => @trigger \pause
    | \playing, \paused, \loading, \editing, \editingPaused => @trigger \quit
    | \menus => # already in the correct state

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

  cleanup-playing: ->

  show-active-menu: ->
    <~ set-timeout _, 400
    @_menus[@_active-menu].make-only-shown-dialogue!

  hide-active-menu: -> @_menus[@_active-menu].hide-dialogue!

  hide-overlay: ->
  show-overlay: ->
  start-event-loop: ->
  stop-event-loop: ->
