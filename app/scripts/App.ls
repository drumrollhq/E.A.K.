module.exports = class App
  states:
    init: {}
    menus: {}
    menus-overlay: {}
    loading: {}
    playing: {}
    paused: {}

  transitions:
    init:
      init: \menus
      load: \menus
      pause: \menusOverlay

    menus:
      pause: \menusOverlay
      load: \loading

    menus-overlay:
      resume: \menus

    loading:
      quit: \menus
      start: \playing

    playing:
      pause: \paused
      load: \loading
      quit: \menus

    paused:
      resume: \playing
      load: \loading
      quit: \resume

  ->
    _.extend this, Backbone.StateMachine, Backbone.Events
    @start-state-machine!

    # last-transition is a promise that needs to complete before transitioning
    @last-transition = effects.load!
      .then -> logged.setup false
      .then ~>
        @game = new Game false
        @router = new Router @{game}
        Backbone.history.start root: window.location.pathname
