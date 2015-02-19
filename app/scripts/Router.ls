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
    if @app.current-state is \init
      user.load-game @app.save-games.latest!
        .then @app.play-user-game
