mediator = require "game/mediator"

module.exports = class LevelLoader extends Backbone.Model
  defaults:
    stage: ""
    progress: null

  initialize: ->
    @assetQueue = []
    @loadingAssets = false

  load: ->
    @set "stage", "Fetching levels"

    ($.get (@get "url"), (data) =>
      @set "stage", ""
      @set "base", data.base
      @set "data", data.levels
      mediator.LevelStore = data.levels
      @trigger "load:done"
    ).fail =>
      @set "stage", "Failed to load levels."
