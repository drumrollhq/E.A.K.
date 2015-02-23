require! {
  'user'
  'lib/channels'
  'logger'
}

$body = $ document.body

module.exports = class Router extends Backbone.Router
  routes:
    'app/:name': 'appOverlay'
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

  play: ->
    if @app.current-state in <[init menus]>
      latest = @app.save-games.latest!
      if latest
        @app.load-game latest
      else window.location.hash = '/menu'
    else if @app._active-play
      @app.load @app._active-play.type, @app._active-play.path
