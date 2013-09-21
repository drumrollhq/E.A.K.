Level = require "game/level"
Bar = require "game/bar"

mediator = require "game/mediator"

module.exports = class Game extends Backbone.Model
  initialize: (load) ->
    if load then @load() else @save()

    @on "change", @save

    @$levelTitle = $ ".levelname"
    @$levelNo = @$levelTitle.find "span"
    @$levelName = @$levelTitle.find "h4"

    barView = new Bar el: $ "#bar"

  defaults:
    level: 0

  startLevel: (n) =>
    if mediator.LevelStore[n] is undefined
      console.log "Cannot find level #{n}", mediator.LevelStore
      mediator.trigger "alert", "That's it! I haven't written any more levels yet!"
      return false

    level = mediator.LevelStore[n]
    @$levelNo.text n+1

    if level.config is undefined or level.config.name is undefined
      @$levelName.text ""
    else
      @$levelName.text level.config.name

    $.hideDialogues =>
      level = new Level level
      mediator.once "levelout", =>
        l = (@get "level") + 1
        @set "level", l
        @startLevel l

  save: =>
    # console.log "Saving to local storage"
    attrs = _.clone @attributes
    localStorage.setItem Game::savefile, JSON.stringify attrs

  load: =>
    attrs = JSON.parse localStorage.getItem Game::savefile
    @set attrs

  savefile: "web-platform-savegame"
