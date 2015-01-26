require! {
  'user'
  'lib/channels'
  'logger'
}

$body = $ document.body

module.exports = class Router extends Backbone.Router
  routes:
    'app/:name': 'appOverlay'
    'area/*path': 'playArea'
    'autoplay': 'autoplay'
    'cutscene/*path': 'playCutscene'
    'menu': 'menu'
    '*default': 'default'

  initialize: (options) ->
    @app = options.app

  default: -> @menu!

  menu: -> @app.show-menu!

  app-overlay: (name) -> @app.show-app-overlay name

  play-cutscene: (path) ->
    @app.load \cutscene, path

  play-area: (path) ->
    @app.load \area, path
