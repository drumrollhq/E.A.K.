World = require "game/physics/world"
DynamicBody = require "game/physics/dynamicBody"
StaticBody = require "game/physics/staticBody"

Renderer = require "game/renderer"
Mapper = require "game/dom/mapper"

Player = require "game/player"

mediator = require "game/mediator"

module.exports = class Level extends Backbone.Model
  initialize: (num) ->
    if mediator.LevelStore[num] is undefined
      console.log "Cannot find level #{num}", mediator.LevelStore
      mediator.trigger "alert", "Well that's odd. We're unable to load level #{num}"
      return false

    level = @level = mediator.LevelStore[num]
    conf = @conf = level.config or {}

    # Set up the HTML/CSS for the level
    renderer = @renderer = new Renderer html: level.html, css: level.css

    if conf.background isnt undefined then renderer.el.style.background = conf.background

    if conf.width isnt undefined
      conf.width = parseFloat conf.width
      renderer.setWidth conf.width
    if conf.height isnt undefined
      conf.height = parseFloat conf.height
      renderer.setHeight conf.height

    # Build a map of DOM elements
    map = renderer.map()

    world = @world = new World renderer.$el

    # Test physics:
    for shape in map
      if shape.data.dynamic is undefined
        body = new StaticBody shape
      else
        body = new DynamicBody shape
      body.attachTo world

    @addBorders conf.borders

    # Add player
    player = new Player conf.player, renderer.width, renderer.height
    player.body.attachTo world
    player.$el.appendTo renderer.el

  addBorders: (borders = "none") ->
    if borders is "none" then return
    if borders is "all" then borders = top: true, right: true, bottom: true, left: true

    t = 400

    w = @renderer.width
    h = @renderer.height

    if borders.top is true
      shape =
        width: w * 2
        height: t
        x: 0
        y: -t / 2
      (new StaticBody shape).attachTo @world

    if borders.bottom is true
      shape =
        width: w * 2
        height: t
        x: 0
        y: h + t / 2
      (new StaticBody shape).attachTo @world

    if borders.left is true
      shape =
        width: t
        height: h * 2
        x: w + t / 2
        y: 0
      (new StaticBody shape).attachTo @world

    if borders.right is true
      shape =
        width: t
        height: h * 2
        x: -t / 2
        y: 0
      (new StaticBody shape).attachTo @world
