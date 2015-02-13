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
    '*default': 'default'

  initialize: (options) ->
    @app = options.app

  default: -> @menu!

  menu: -> @app.show-menu!

  app-overlay: (name) -> @app.show-app-overlay name
