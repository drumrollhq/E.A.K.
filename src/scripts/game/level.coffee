Renderer = require "game/renderer"

mediator = require "game/mediator"

module.exports = class Level extends Backbone.Model
  initialize: (num) ->
    if window.LevelStore[num] is undefined
      console.log "Cannot find level #{num}", window.LevelStore
      mediator.trigger "alert", "Well that's odd. We're unable to load level #{num}"
      return false

    level = window.LevelStore[num]

    renderer = new Renderer html: level.html, css: level.css
