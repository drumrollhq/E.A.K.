require! <[
  plugins
  game/Game
  Router
  game/mediator
  game/event-loop
  logger
]>

module.exports = class Init extends Backbone.View
  initialize: ->
    # Check this browser is capable of running EAK
    unless @compatible!
      @$ \#incompatible .show-dialogue!
      return

    event-loop.init!
    event <- logger.start 'session', ua: navigator.user-agent

    # Hide the loader and start up the game.
    @$ \.loader .hide-dialogue!

    game = new Game false, event.id

    # Start up the Backbone router
    router = new Router!

    Backbone.history.start root: window.location.pathname

  # Uses modernizr to check that all the browser features that EAK requires are present. Returns true
  # if they are, false if not.
  compatible: ->
    needed = <[ csstransforms cssanimations csstransitions csscalc boxsizing canvas webworkers ]>

    lacking = _.filter needed, ( not Modernizr. )

    if lacking.length > 0
      console.log 'Lacking:', lacking
      logger.log 'incompatible', {lacking}
      false
    else
      true
