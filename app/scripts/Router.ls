require! {
  'user'
  'lib/channels'
  'logger'
}

$body = $ document.body

module.exports = class Router extends Backbone.Router
  routes:
    'app/:name': 'appOverlay'
    'app/:name/:arg1': 'appOverlayArgs'
    'menu': 'menu'
    'play': 'play'
    '*default': 'default'

  initialize: (options) ->
    @app = options.app

  default: ->
    @menu!

  menu: ->
    @app.show-menu!

  app-overlay: (name) ->
    @app.show-app-overlay name

  app-overlay-args: (name, ...args) ->
    @app.show-app-overlay name, args

  play: ->
    if @app.current-state in <[init menus]>
      latest = @app.save-games.latest!
      if latest
        @app.load-game latest
      else window.location.hash = '/menu'
    else if @app._active-play
      @app.load @app._active-play.type, @app._active-play.path
