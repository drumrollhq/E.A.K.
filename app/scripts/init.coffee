LevelLoader = require "loader/LevelLoader"
LoaderView = require "loader/LoaderView"
KittenQuest = require "KittenQuest"

module.exports = class Init extends Backbone.View
  initialize: ->
    if not @compatible()
      (@$ "#incompatible").showDialogue()
      return

    app = new KittenQuest el: @$ ".app"

    loader = new LevelLoader url: "data/levels.json"
    loaderView = new LoaderView model: loader, el: @$ ".loader"

    loaderView.render()

    loader.on "load:done", ->
      loaderView.$el.switchDialogue app.$menu
      setTimeout ->
        loaderView.remove()
      , 500

    loader.load()

  compatible: ->
    needed = ["csstransforms", "csstransforms3d", "cssanimations", "csscalc"
      "csstransitions", "boxsizing", "canvas"]

    works = true

    for need in needed
      console.log "#{need}: #{Modernizr[need]};"
      works = works and Modernizr[need]

    works
