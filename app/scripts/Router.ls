require! {
  'user'
  'lib/channels'
  'logger'
}

$body = $ document.body

module.exports = class Router extends Backbone.Router
  routes:
    'app/:name': 'overlay'
    'area/*path': 'playArea'
    'autoplay': 'autoplay'
    'cutscene/*path': 'playCutScene'
    'menu': 'menu'
    '*default': 'default'

  initialize: (options) ->
    @app = options.app

  default: -> window.location.hash = '#/menu'

  menu: -> @app.show-menu!
  overlay: ({name}) -> @app.show-overlay name
