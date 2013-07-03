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
  initialize: ->