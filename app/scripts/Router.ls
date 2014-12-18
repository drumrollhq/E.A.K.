require! {
  'lib/channels'
  'logger'
}

module.exports = class Router extends Backbone.Router
  routes:
    'about': 'about'
    'play/area/*path': 'playLocalArea'
    'play/cutscene/*path': 'playCutScene'
    'load': 'load'
    'home': 'goHome'
    '*default': 'menu'

  initialize: ->
    @last-hash = '#'
    @on 'route' ->
      if ga? then ga 'send' 'pageview' page: location.pathname + location.search + location.hash

  should-prevent-route: ->
    if $ document.body .has-class \editor
      return true
    else
      @last-hash = window.location.hash
      return false

  prevent-route: ->
    window.location.hash = @last-hash

  stop-game: (callback) ~>
    # Stopping the game takes some time, hence the callback. However, if there isn't a
    # game to be stopped, the callback will never get called. So along with the callback, we
    # send a status object. Whatever picks up this event should set status.handled to true,
    # so we can trigger the callback immediately. This is a bit of a hack, but as far as
    # I'm aware, there's no way to tell if an event has been handled with Backbone.Events
    payload = handled: false, callback: callback
    channels.game-commands.publish-sync command: \stop, payload: payload

    unless payload.handled => callback!

  # Show the main menu
  menu: ~>
    if @should-prevent-route! then return @prevent-route!
    <- @stop-game
    logger.log 'page' type: 'menu'
    $ '#main .menu' .make-only-shown-dialogue!

  # Show the about page
  about: ~>
    if @should-prevent-route! then return @prevent-route!
    <- @stop-game
    logger.log 'page' type: 'about'
    $ '#main .about' .make-only-shown-dialogue!

  # TODO: Loading
  load: ~>
    if @should-prevent-route! then return @prevent-route!
    channels.alert.publish msg: 'I haven\'t implemented loading yet. Sorry!'

  # TODO: Add a proper screen for reaching the end of the game. At the moment,
  # we just redirect to a feedback form.
  go-home: ~>
    if @should-prevent-route! then return @prevent-route!
    <- logger.log 'finish', {}
    location.href = 'https://docs.google.com/forms/d/1gMg8FcbDmVH-FPYvAaiO33mVp5EaHndu1W3l97RN00s/viewform?usp=send_form'

  play-local-area: (path) ~>
    if @should-prevent-route! then return @prevent-route!
    <- @stop-game
    <- $.hide-dialogues
    channels.stage.publish type: 'area', url: "/levels/#path"

  play-cut-scene: (path) ~>
    if @should-prevent-route! then return @prevent-route!
    <- @stop-game
    <- $.hide-dialogues
    channels.stage.publish type: 'cutscene', url: path
