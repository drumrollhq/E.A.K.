require! <[ loader/LevelLoader loader/LoaderView KittenQuest ]>

module.exports = class Init extends Backbone.View
  initialize: ->
    unless @compatible!
      @$ \#incompatible .show-dialogue!
      return

    app = new KittenQuest el: @$ \.app

    @$ \.loader .switch-dialogue app.$menu

  compatible: ->
    needed = <[ csstransforms cssanimations csstransitions csscalc boxsizing canvas webworkers ]>

    lacking = _.filter needed, ( not Modernizr. )

    if lacking.length > 0
      console.log 'Lacking:', lacking
      false
    else
      true
