mediator = require "game/mediator"

module.exports = class LevelLoader extends Backbone.Model
  defaults:
    stage: ""
    progress: null

  initialize: ->
    # @on "change:data", @loadAssets

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

  loadAssets: (model, levels) =>
    for level in levels
      if level.config.assets isnt undefined
        @queueAsset asset for asset in level.config.assets

  queueAsset: (url) ->
    @assetQueue.push url

    if not @loadingAssets
      @processQueue()

  processQueue: =>
    if @assetQueue.length is 0
      @loadingAssets = no
      @set "stage", ""
      @trigger "load:done"
    else
      @loadingAssets = yes
      url = @assetQueue.shift()
      @set "stage", url
      img = new Image()
      img.addEventListener "load", =>
        @processQueue()

      img.addEventListener "error", =>
        @trigger "load:failed", url
        @processQueue()

      img.src = (@get "base") + url
