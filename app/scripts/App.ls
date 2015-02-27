require! {
  'Router'
  'audio/effects'
  'audio/music-manager'
  'game/area/background'
  'game/event-loop'
  'game/load'
  'game/pauser'
  'lib/channels'
  'lib/parse'
  'loader/LoaderView'
  'logger'
  'settings'
  'ui/Bar'
  'ui/MainMenuView'
  'ui/alert'
  'ui/overlay-views'
  'user'
}

const stage-types = <[cutscene area]>
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
        Promise.reject e

  show-menu: (menu = 'main') ->
    @switch-menu menu

    console.log @current-state
    switch @current-state
    | \init => @trigger-async \init
    | \menusOverlay => @trigger-async \resume
    | otherwise => @trigger-async \quit

  play-user-game: ~>
    @_active-play = null
    saved-stage = user.game.active-stage!
    @load saved-stage.type, saved-stage.url

  load-game: (game) ->
    @show-loader!
    user.load-game game
      .then @play-user-game
      .catch (e) ~>
        channels.alert.publish msg: error-message e
        @hide-loader!
        @show-menu!
        Promise.reject e

  load: (type, path, options) ->
    p = if @overlay-active!
      @trigger-async \resume
    else if @current-state is \loading
      @trigger-async \quit
    else Promise.delay 0

    p.finally ~>
      window.location.hash = '/play'
      @trigger-async \load, {type, path, options} unless @_active-play === {type, path}

  load-path: (path) ->
    url = parse.url path
    if url.protocol isnt 'eak:' then throw new Error 'non-eak url!' # TODO: figure out what happens here
    [type, path] = url.pathname.split '/'
    @load type, path, url.query

  error: (msg) ->
    window.alert msg

  switch-menu: (name) -> @_active-menu = name

  initialized: ~>
    $overlay-views = $ '#overlay-views'
    @bar = new Bar el: ($ '#bar'), views: overlay-views {settings, user, $overlay-views, save-games: @save-games, app: this}
      ..show!
      ..on \dismiss, ~> @dismiss-app-overlay!

    # Hide the loader and start up the game.
    $ \.loader .hide-dialogue!
    @_menus = {
      main: new MainMenuView app: this, collection: @save-games, el: $ '#main-menu'
    }

    channels.game-commands.filter ( .command is \edit ) .subscribe ~> @edit!
    channels.stage.subscribe ({url}) ~> @load-path url

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
      window.location.hash = "#/play"
    else
      window.location.hash = '#/menu'

  switch-overlay: (name = @_active-overlay) ->
    console.log "switch overlay #{@_active-overlay} -> #name"
    @_active-overlay = name
    if @overlay-active!
      @bar.activate name

  overlay-active: -> @current-state in <[menusOverlay paused editingPaused]>

  edit: ->
    if @_stage and @_stage.is-editable! and @current-state is \playing
      @trigger-async 'edit'

  cleanup-playing: ->
    @_active-play = null
    if @_stage
      @_stage = null
      that.cleanup!

  # After a stage is completed, we leave behind the background and music in case
  # they are reused. This function cleans those up, and is used when transitioning
  # to menus.
  cleanup-playing-remains: ->
    background.clear!
    music-manager.start-track 'none'

  # Load and set up a new stage of the game.
  # Type is the type of stage - either area or cutscene.
  # Path is the path to that stage
  # Options is passed into the stage
  start-loader: ({type, path, options}) !->
    unless type in stage-types then throw new Error "Bad stage type #type!"
    @show-loader!

    # Keep track of what stage is currently playing. This lets us return from menus
    # and overlays without having to reload everything.
    @_active-play = {type, path}

    # Keep track of the currently loading game, to make sure only one thing can be
    # loaded at once
    @_current-loader = load[type] path, this, options # First, we load the stage
      .cancellable!
      .then (stage) ~>
        @_stage = stage
        user.game.find-or-create-stage stage.save-defaults!, true
      .then (saved-stage) ~>
        @_stage.once \next, (path) ~> @load-path path
        @trigger \start
        @_stage.start user.game
      .catch Promise.CancellationError, ->
      .catch (e) ~>
        console.error e
        channels.alert.publish msg: error-message e
        window.location.href = '#/menu'
        Promise.reject e
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
    if @_stage and @_stage.is-editable!
      @_stage.edit!
      @_stage.once 'stop-editor' ~> @trigger \editFinished

  hide-editor: ->
    console.log 'hide-editor'
    if @_stage then @_stage.hide-editor!
