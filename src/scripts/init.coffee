Loader = require "loader/loader"
LoaderView = require "loader/loaderView"

module.exports = class Init extends Backbone.View
  initialize: ->
    if not @compatible()
      (@$ "#incompatible").showDialogue()
      return

    loader = new Loader url: "data/levels.json"
    loaderView = new LoaderView model: loader, el: @$ ".loader"

    loader.load()

    loader.on "load:done", ->
      loaderView.hide()

  compatible: ->
    needed = ["csstransforms", "csstransforms3d", "cssanimations", "csscalc"
      "csstransitions", "boxsizing", "canvas"]

    works = true

    for need in needed
      works = works and Modernizr[need]

    works