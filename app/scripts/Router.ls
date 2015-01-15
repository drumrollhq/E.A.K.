require! {
  'user'
  'lib/channels'
  'logger'
}

$body = $ document.body

module.exports = class Router extends Backbone.Router
  routes:
    'autoload': 'autoload'
    'about': 'about'
    'play/area/*path': 'playLocalArea'
    'play/cutscene/*path': 'playCutScene'
    'load': 'load'
    'home': 'goHome'
    'app/:name': 'app'
    '*default': 'default'

  initialize: ({game}) ->
    @game = game
    @restore-hash = '#'
    @current = '#'
    @on 'route' ~>
      @current = window.location.hash
      if ga? then ga 'send' 'pageview' page: location.pathname + location.search + location.hash

  should-prevent-route: ->
    if $body.has-class \editor and not $body.has-class 'paused'
      return true
    else
      @restore-hash = window.location.hash
      return false

  prevent-route: ->
    window.location.hash = @restore-hash

  stop-game: (new-game, callback) ~>
    if typeof new-game is 'function'
      callback = new-game
      new-game = null

    channels.page.publish name: 'none'
    if new-game is @game.current then return callback!

    # Stopping the game takes some time, hence the callback. However, if there isn't a
    # game to be stopped, the callback will never get called. So along with the callback, we
    # send a status object. Whatever picks up this event should set status.handled to true,
    # so we can trigger the callback immediately. This is a bit of a hack.
    payload = handled: false, callback: callback
    channels.game-commands.publish-sync command: \stop, payload: payload

    unless payload.handled => callback!

  default: -> window.location.hash = '#/app/menu'

  autoload: ->
    <- user.ensure-loaded
    game <- user.get-game
    /* if game.get 'activeArea'
      window.location.hash = "#/play/area/#{game.get 'activeArea'}"
    else
      window.location.hash = '#/play/cutscene/intro'*/

  # TODO: Add a proper screen for reaching the end of the game. At the moment,
  # we just redirect to a feedback form.
  go-home: ~>
    @last-non-overlay = null
    if @should-prevent-route! then return @prevent-route!
    <- logger.log 'finish', {}
    location.href = 'https://docs.google.com/forms/d/1gMg8FcbDmVH-FPYvAaiO33mVp5EaHndu1W3l97RN00s/viewform?usp=send_form'

  play-local-area: (path) ~>
    @last-non-overlay = null
    if @should-prevent-route! then return @prevent-route!
    url = "/levels/#path"
    <- @stop-game url
    <- $.hide-dialogues
    channels.stage.publish type: 'area', url: url

  play-cut-scene: (path) ~>
    @last-non-overlay = null
    if @should-prevent-route! then return @prevent-route!
    <- @stop-game path
    <- $.hide-dialogues
    channels.stage.publish type: 'cutscene', url: path

  app: (name) ->
    unless @last-non-overlay then @last-non-overlay = @current
    channels.page.publish name: (camelize name), prev: @last-non-overlay
