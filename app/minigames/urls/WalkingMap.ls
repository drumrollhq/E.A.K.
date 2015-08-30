exports, require, module <- require.register 'minigames/urls/WalkingMap'

require! {
  'assets'
  'game/scene/TiledSpriteContainer'
  'lib/keys'
  'lib/math/Vector'
  'minigames/urls/Zoomer'
}

const max-player-speed = 0.3px
const player-accel = 0.03px

const draw-rects = false
colors = [0xFF0000 0x00FF00 0x0000FF 0x00FFFF 0xFF00FF 0xFFFF00]

module.exports = class WalkingMap extends PIXI.Container
  player-scale: 0.5
  (@camera, @layer, @player, {width, height, map-url, scale, position, buildings, player-scale, @start, @rects}) ->
    super!
    @bg = new TiledSpriteContainer map-url, width, height, false
    @bg.player-scale = @player-scale
    @full-width = width
    @full-height = height
    if player-scale then @player-scale = player-scale

    @player.v ?= new Vector 0, 0

    @scale.x = @scale.y = scale
    if position then @position <<< position.{x, y}

    if buildings
      @buildings = buildings |> Obj.map (building) ~>
        new WalkingMap @camera, @layer, @player, building <<< {width, height}
    else @buildings = {}

    @zoomer = new Zoomer @camera, @player, @bg, @buildings, false, false
      ..on \path (...args) ~> @emit \path ...args
      ..on \zoom-in ~> @deactivate!
      ..on \zoom-out ~> @activate!
    @add-child @zoomer

    for rect in @rects when rect.4?
      rect.4 .= split ':' if typeof! rect.4 isnt \Array

    if draw-rects
      @dbg = new PIXI.Graphics!
      @dbg-labels = new PIXI.Container!
      @add-child @dbg
      @add-child @dbg-labels

    @on \enter (building) ->
      building = camelize building
      if @buildings[building] then @zoomer.zoom-to building

  setup: ->
    @bg.setup!
    for _, building of @buildings => building.setup!

  step: (t) ->
    @zoomer.step t
    for _, building of @buildings => building.step t
    unless @active then return
    if keys.up
      @player.v.y -= player-accel
    else if keys.down
      @player.v.y += player-accel
    else
      @player.v.y = 0

    if keys.right
      @player.v.x += player-accel
    else if keys.left
      @player.v.x -= player-accel
    else
      @player.v.x = 0

    @player.v.constrain max-player-speed
    @player.x += @player.v.x * t
    @player.y += @player.v.y * t

    if draw-rects
      @dbg.clear!
      for rect, i in @rects
        unless @dbg-labels.children[i]
          @dbg-labels.add-child new PIXI.Text "rects[#{i}]", fill: colors[i % colors.length], font: '12px Arial'

        @dbg-labels.children[i] <<< x: rect.0, y: rect.1, text: "rects[#{i}] #{if rect.4 then "(#{rect.4.join ':'})" else ''}"
        @dbg
          ..line-style 1, colors[i % colors.length]
          ..draw-rect rect.0, rect.1, rect.2, rect.3

    @resolve @player, 1

  resolve: (vec, dist) ->
    {x, y} = vec
    emits = []
    has-path = false
    for rect, i in @rects
      [left, top, width, height] = rect
      right = left + width
      bottom = top + height

      if left <= x <= right and top <= y <= bottom
        if rect.4?
          if rect.4.0 is \path
            unless has-path
              emits[*] = rect.4
              has-path = true
            continue
          else
            emits[*] = rect.4

        left-resolve = x - left
        right-resolve = right - x
        top-resolve = y - top
        bottom-resolve = bottom - y
        min = Math.min left-resolve, right-resolve, top-resolve, bottom-resolve
        switch
        | left-resolve is min => x = left - dist
        | right-resolve is min => x = right + dist
        | top-resolve is min => y = top - dist
        | bottom-resolve is min => y = bottom + dist

    vec <<< {x, y}
    for emit in emits => @emit ...emit

  set-viewport: (top, left, bottom, right) ->
    @bg.set-viewport top, left, bottom, right

  activate: ->
    @active = true
    if draw-rects and @dbg then @dbg-labels.visible = @dbg.visible = true

  deactivate: ->
    @active = false
    if draw-rects and @dbg then @dbg-labels.visible = @dbg.visible = false
