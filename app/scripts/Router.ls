require! {
  'channels'
  'logger'
}

module.exports = class Router extends Backbone.Router
  routes:
    'about': 'about'
    'play/levels/*path': 'playLocalLevel'
    'load': 'load'
    'home': 'goHome'
    '*default': 'menu'

  stop-game: (callback) ->
    # Stopping the game takes some time, hence the callback. However, if there isn't a
    # game to be stopped, the callback will never get called. So along with the callback, we
    # send a status object. Whatever picks up this event should set status.handled to true,
    # so we can trigger the callback immediately. This is a bit of a hack, but as far as
    # I'm aware, there's no way to tell if an event has been handled with Backbone.Events
    payload = handled: false, callback: callback
    channels.game-commands.publish-sync command: \stop, payload: payload

    unless payload.handled => callback!

  # Show the main menu
  menu: ->
    <- @stop-game
    logger.log 'show-menu'
    $ '#main .menu' .make-only-shown-dialogue!

  # Show the about page
  about: ->
    <- @stop-game
    logger.log 'show-about'
    $ '#main .about' .make-only-shown-dialogue!

  # TODO: Loading
  load: ->
    channels.alert.publish msg: 'I haven\'t implemented loading yet. Sorry!'

  # TODO: Add a proper screen for reaching the end of the game. At the moment,
  # we just redirect to a feedback form.
  go-home: ->
    <- logger.log 'show-form', {}
    location.href = 'https://docs.google.com/forms/d/1q_uwYzcNSpGIvvNKc4LHoKqj7tta-uQveWjaiskOVrA/viewform'

  # Plays a local ('official') level from the repo. TODO: Playing levels from
  # Thimble, and maybe even arbitrary URLs
  play-local-level: (path) ->
    <- @stop-game
    <- $.hide-dialogues
    channels.levels.publish url: "/levels/#path"
