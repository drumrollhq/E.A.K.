require! {
  'game/mediator'
}

module.exports = class Router extends Backbone.Router
  routes:
    'about': 'about'
    'play/levels/*path': 'playLocalLevel'
    '*default': 'menu'

  stop-game: ->
    mediator.trigger 'stop-game'

  menu: ->
    @stop-game!
    $ '#main .menu' .make-only-shown-dialogue!

  about: ->
    @stop-game!
    $ '#main .about' .make-only-shown-dialogue!

  play-local-level: (path) -> console.log path
