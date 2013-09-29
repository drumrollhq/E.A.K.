World = require "game/physics/world"
DynamicBody = require "game/physics/dynamicBody"
StaticBody = require "game/physics/staticBody"

Renderer = require "game/renderer"
Mapper = require "game/dom/mapper"

ElementLoader = require "loader/elementLoader"
LoaderView = require 'loader/loaderView'

Editor = require "game/editor/editor"
EditorView = require "game/editor/view"

HintController = require "game/hints/hintController"

Player = require "game/player"

mediator = require "game/mediator"

module.exports = class Level extends Backbone.Model
  initialize: (level) ->
    @level = level
    conf = @conf = level.config or {}

    # Set up the HTML/CSS for the level
    renderer = @renderer = new Renderer
      html: level.html
      css: level.css
      root: $ "#levelcontainer"

    if conf.background isnt undefined then renderer.el.style.background = conf.background

    if conf.width isnt undefined
      conf.width = parseFloat conf.width
      renderer.setWidth conf.width
    if conf.height isnt undefined
      conf.height = parseFloat conf.height
      renderer.setHeight conf.height

    @addTarget conf.target

    loader = new ElementLoader el: @renderer.$el
    loaderView = new LoaderView model: loader
    loaderView.$el.appendTo "#main > .app"

    loaderView.render()

    mediator.paused = true

    loader.once "done", =>

      $.hideDialogues()

      setTimeout =>
        ($ document.body).addClass "playing"

        mediator.paused = false

        @addBodiesFromDom()
        @addPlayer conf.player
        @addBorders conf.borders


        @hintController = new HintController hints: conf.hints

        @listenTo mediator, "edit", @startEditor
        @listenTo mediator, "restart", @restart

        @listenTo mediator, "frame:process", @checkPlayerIsInWorld
        @listenTo mediator, "kittenfound", @complete
      , 600

    loader.start()

  addBodiesFromDom: (createWorld=true)=>
    # Build a map of DOM elements
    map = @renderer.createMap()

    if createWorld
      world = @world = new World @renderer.$el
    else
      world = @world

    # Create bodies from DOM:
    @domBodies = for shape in map
      if shape.data.dynamic is undefined
        body = new StaticBody shape
      else
        body = new DynamicBody shape
      body.attachTo world
      body

  removeDOMBodies: =>
    for body in @domBodies
      if body.def.data.target is undefined
        body.destroy()

  addTarget: (targetHTML) =>
    $target = $ targetHTML
    $target.addClass "entity"
    $target.attr "data-target", "data-target"
    $target.attr "data-id", "ENTITY_TARGET"
    $target.appendTo @renderer.$el

  addPlayer: (playerConf) =>
    player = new Player playerConf, @renderer.width, @renderer.height
    player.body.attachTo @world
    player.$el.appendTo @renderer.el
    player.id = "#{@renderer.el.id}-player"
    player.$el.attr "id", player.id
    @player = player

    # Get starting positions:
    target = (@renderer.$el.children "[data-target]")
    @startPos = player: player.el.getBoundingClientRect()

    if target.length >= 1
      @startPos.target = (@renderer.$el.children "[data-target]")[0].getBoundingClientRect()

  restart: =>
    @renderer.resize()
    @redrawFrom @level.html, @level.css
    @player.body.reset()

  redrawFrom: (html, css) =>
    # Preserve entities:
    entities = (@renderer.$el.children ".entity").detach()

    @renderer.setHTMLCSS html, css

    # Reset DOM bodies
    @removeDOMBodies()
    @addBodiesFromDom false

    # Replace entities
    entities.appendTo @renderer.$el

  addBorders: (borders = "none") ->
    if borders is "none" then return
    if borders is "all" then borders = top: true, right: true, bottom: true, left: true

    t = 400

    w = @w = @renderer.width
    h = @h = @renderer.height

    if borders.top is true
      shape =
        width: w * 2
        height: t
        x: 0
        y: -t / 2
        id: "BORDER_TOP"
      (new StaticBody shape).attachTo @world

    if borders.bottom is true
      shape =
        width: w * 2
        height: t
        x: 0
        y: h + t / 2
        id: "BORDER_BOTTOM"
      (new StaticBody shape).attachTo @world

    if borders.right is true
      shape =
        width: t
        height: h * 2
        x: w + t / 2
        y: 0
        id: "BORDER_RIGHT"
      (new StaticBody shape).attachTo @world

    if borders.left is true
      shape =
        width: t
        height: h * 2
        x: -t / 2
        y: 0
        id: "BORDER_LEFT"
      (new StaticBody shape).attachTo @world

  checkPlayerIsInWorld: =>
    @player.body.positionUncorrected (pos) ->
      xpad = 100
      padTop = 100
      padBottom = 200

      unless (-xpad < pos.x < @w + xpad) and (-padTop < pos.y < @h + padBottom)
        @player.body.reset()
        mediator.trigger "falloutofworld"
        return

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

      @hintController.destroy()

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

  startEditor: =>

    unless ($ document.body).hasClass "editor"
      mediator.paused = true

      # Stop the player from rolling off an edge when we've finished editing
      @player.body.halt()

      editor = new Editor
        html: @renderer.currentHTML
        css: @renderer.currentCSS
        originalHTML: @level.html
        originalCSS: @level.css

      editorView = new EditorView model: editor, renderEl: @renderer.$el, el: $ "#editor"

      editorView.render()

      editorView.$el.appendTo $ "#editor"

      @renderer.editor = true
      @renderer.resize()

      editor.once "save", =>
        editorView.restoreEntities()
        editorView.remove()
        @renderer.editor = false
        @renderer.resize()
        @redrawFrom (editor.get "html"), (editor.get "css")
        mediator.paused = false
