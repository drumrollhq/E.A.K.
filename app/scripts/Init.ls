require! <[ loader/LevelLoader loader/LoaderView game/Game Router game/mediator ]>

module.exports = class Init extends Backbone.View
  initialize: ->
    # Check this browser is capable of running EAK
    unless @compatible!
      @$ \#incompatible .show-dialogue!
      return

    # Hide the loader and start up the game.
    @$ \.loader .hide-dialogue!

    game = new Game false

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
      false
    else
      true
