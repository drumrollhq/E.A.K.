require! <[ loader/LevelLoader loader/LoaderView KittenQuest Router game/mediator ]>

module.exports = class Init extends Backbone.View
  initialize: ->
    unless @compatible!
      @$ \#incompatible .show-dialogue!
      return

    @$ \.loader .hide-dialogue!

    app = new KittenQuest el: @$ \.app

    router = new Router!
    Backbone.history.start!

  compatible: ->
    needed = <[ csstransforms cssanimations csstransitions csscalc boxsizing canvas webworkers ]>

    lacking = _.filter needed, ( not Modernizr. )

    if lacking.length > 0
      console.log 'Lacking:', lacking
      false
    else
      true
