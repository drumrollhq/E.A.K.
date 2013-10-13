require! <[ loader/LevelLoader loader/LoaderView KittenQuest ]>

module.exports = class Init extends Backbone.View
  initialize: ->
    unless @compatible!
      @$ \#incompatible .show-dialogue!
      return

    app = new KittenQuest el: @$ \.app

    loader = new LevelLoader url: 'data/levels.json'
    loader-view = new LoaderView model: loader, el: @$ \.loader

    loader-view.render!

    loader.on \load:done ->
      loader-view.$el.switch-dialogue app.$menu
      <- set-timeout _, 500
      loader-view.remove!

    loader.load!

  compatible: ->
    needed = <[ csstransforms cssanimations csstransitions csscalc boxsizing canvas webworkers ]>

    lacking = _.filter needed, ( not Modernizr. )

    if lacking.length > 0
      console.log 'Lacking:', lacking
      false
    else
      true
