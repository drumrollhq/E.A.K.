require! {
  'game/mediator'
}

module.exports = class Router extends Backbone.Router
  routes:
    'about': 'about'
    'play/levels/*path': 'playLocalLevel'
    'load': 'load'
    '*default': 'menu'

  stop-game: (callback) ->
    # Stopping the game takes some time, hence the callback. However, if there isn't a
    # game to be stopped, the callback will never get called. So along with the callback, we
    # send a status object. Whatever picks up this event should set status.handled to true,
    # so we can trigger the callback immediately.
    status = handled: false
    mediator.trigger 'stop-game', status, callback

    unless status.handled => callback!

  menu: ->
    <- @stop-game
    mediator.trigger 'clearBackground'
    $ '#main .menu' .make-only-shown-dialogue!

  about: ->
    <- @stop-game
    mediator.trigger 'clearBackground'
    $ '#main .about' .make-only-shown-dialogue!

  load: ->
    mediator.trigger 'alert' 'I haven\'t implemented loading yet. Sorry!'

  play-local-level: (path) ->
    <- @stop-game
    <- $.hide-dialogues
    mediator.trigger 'start-local-level', path
