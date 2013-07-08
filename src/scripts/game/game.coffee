World = require "game/physics/world"
StaticBody = require "game/physics/staticBody"
DynamicBody = require "game/physics/dynamicBody"

Player = require "game/player"
Level = require "game/level"
Editor = require "game/editor"

DomBuilder = require "game/dom/builder"
Renderer = require "game/renderer"

mediator = require "game/mediator"

module.exports = class Game extends Backbone.Model
  initialize: (load) ->
    if load then @load() else @save()

    @on "change", @save

    level = new Level @get "level"

  defaults:
    level: 1

  save: =>
    attrs = _.clone @attributes
    localStorage.setItem Game::savefile, JSON.stringify attrs

  load: =>
    attrs = JSON.parse localStorage.getItem Game::savefile
    @set attrs

  savefile: "web-platform-savegame"
