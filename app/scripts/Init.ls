require! <[ loader/LevelLoader loader/LoaderView game/Game Router game/mediator ]>

module.exports = class Init extends Backbone.View
  initialize: ->
    unless @compatible!
      @$ \#incompatible .show-dialogue!
      return

    @$ \.loader .hide-dialogue!

    game = new Game false

    router = new Router!

    Backbone.history.start root: window.location.pathname

  compatible: ->
    needed = <[ csstransforms cssanimations csstransitions csscalc boxsizing canvas webworkers ]>

    lacking = _.filter needed, ( not Modernizr. )

    if lacking.length > 0
      console.log 'Lacking:', lacking
      false
    else
      true
