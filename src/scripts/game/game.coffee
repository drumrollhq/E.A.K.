Level = require "game/level"

mediator = require "game/mediator"

module.exports = class Game extends Backbone.Model
  initialize: (load) ->
    if load then @load() else @save()

    @on "change", @save

    level = new Level @get "level"

  defaults:
    level: 0

  save: =>
    attrs = _.clone @attributes
    localStorage.setItem Game::savefile, JSON.stringify attrs

  load: =>
    attrs = JSON.parse localStorage.getItem Game::savefile
    @set attrs

  savefile: "web-platform-savegame"
