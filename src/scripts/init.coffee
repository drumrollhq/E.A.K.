Loader = require "loader/loader"
LoaderView = require "loader/loaderView"
App = require "app"

module.exports = class Init extends Backbone.View
  initialize: ->
    if not @compatible()
      (@$ "#incompatible").showDialogue()
      return

    app = new App el: @$ ".app"

    loader = new Loader url: "data/levels.json"
    loaderView = new LoaderView model: loader, el: @$ ".loader"

    loaderView.render()

    loader.load()

    loader.on "load:done", ->
      loaderView.hide()

      # Give a little time for the load dialogue to go away
      setTimeout (-> app.render()), 400

  compatible: ->
    needed = ["csstransforms", "csstransforms3d", "cssanimations", "csscalc"
      "csstransitions", "boxsizing", "canvas"]

    works = true

    for need in needed
      works = works and Modernizr[need]

    works