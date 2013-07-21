World = require "game/physics/world"
DynamicBody = require "game/physics/dynamicBody"
StaticBody = require "game/physics/staticBody"

Renderer = require "game/renderer"
Mapper = require "game/dom/mapper"

Player = require "game/player"

mediator = require "game/mediator"

module.exports = class Level extends Backbone.Model
  initialize: (level) ->
    @level = level
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
    player.id = "#{renderer.el.id}-player"
    player.$el.attr "id", player.id
    @player = player

    # Get starting positions:
    target = (renderer.$el.children "[data-target]")
    @startPos = player: player.el.getBoundingClientRect()

    if target.length >= 1
      @startPos.target = (renderer.$el.children "[data-target]")[0].getBoundingClientRect()

    # When the kitten is found, the level is complete:
    @listenTo mediator, "kittenfound", @complete

    @stopped = false

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

  complete: =>
    if not @stopped
      @stopped = true

      $playertarget = $ "<div></div>"
      $playertarget.css
        position: "absolute"
        top: 0
        left: 0
        bottom: 0
        right: 0

      $playertarget.appendTo document.body

      $playerEl = @player.$el
      $targetEl = @renderer.$el.children "[data-target]"

      $playerEl.appendTo $playertarget
      $targetEl.appendTo $playertarget

      $playerEl.css
        position: "absolute"
        top: @startPos.player.top
        left: @startPos.player.left
        width: @startPos.player.width
        height: @startPos.player.height
      $targetEl.css
        position: "absolute"
        top: @startPos.target.top
        left: @startPos.target.left
        width: @startPos.target.width
        height: @startPos.target.height

      @renderer.remove =>
        # approx center:
        t = $targetEl[0].getBoundingClientRect()
        tx = t.left + t.width / 2
        ty = t.top + t.height / 2
        p = $playerEl[0].getBoundingClientRect()
        px = p.left + p.width / 2
        py = p.top + p.height / 2

        cx = (px + tx) / 2
        cy = (py + ty) / 2

        $playertarget.css (Modernizr.prefixed "transformOrigin"), "#{cx}px #{cy}px"
        $playertarget.addClass "level-entity-fadeout"

        setTimeout =>
          $playertarget.remove()
          @world.remove()
          @player.remove()
          mediator.trigger "levelout"
          @stopListening()
        , 500
