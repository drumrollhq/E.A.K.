World = require "game/physics/world"

Renderer = require "game/renderer"
Mapper = require "game/dom/mapper"

mediator = require "game/mediator"

module.exports = class Level extends Backbone.Model
  initialize: (num) ->
    if mediator.LevelStore[num] is undefined
      console.log "Cannot find level #{num}", mediator.LevelStore
      mediator.trigger "alert", "Well that's odd. We're unable to load level #{num}"
      return false

    level = mediator.LevelStore[num]

    # Set up the HTML/CSS for the level
    renderer = new Renderer html: level.html, css: level.css

    # Build a map of DOM elements
    map = renderer.map()
