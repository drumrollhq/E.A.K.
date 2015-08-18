exports, require, module <- require.register 'minigames/urls/WalkingMap'

require! {
  'assets'
  'game/scene/TiledSpriteContainer'
  'lib/keys'
  'minigames/urls/Zoomer'
}

const player-speed = 0.3px

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

    @scale.x = @scale.y = scale
    if position then @position <<< position.{x, y}

    if buildings
      @buildings = buildings |> Obj.map (building) ~>
        new WalkingMap @camera, @layer, @player, building <<< {width, height}
    else @buildings = {}

    @zoomer = new Zoomer @camera, @player, @bg, @buildings
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
      @player.y -= player-speed * t
    else if keys.down
      @player.y += player-speed * t

    if keys.right
      @player.x += player-speed * t
    else if keys.left
      @player.x -= player-speed * t

    if draw-rects
      @dbg.clear!
      for rect, i in @rects
        unless @dbg-labels.children[i]
          @dbg-labels.add-child new PIXI.Text "rects[#{i}]", fill: colors[i % colors.length], font: '12px Arial'

        @dbg-labels.children[i] <<< x: rect.0, y: rect.1, text: "rects[#{i}] #{if rect.4 then "(#{rect.4.join ':'})" else ''}"
        @dbg
          ..line-style 1, colors[i % colors.length]
          ..draw-rect rect.0, rect.1, rect.2, rect.3

    @resolve @player, keys.right

  resolve: (vec, dbg) ->
    {x, y} = vec
    emits = []
    for rect, i in @rects
      # if i is 5 and dbg then debugger
      [left, top, width, height] = rect
      right = left + width
      bottom = top + height

      if left <= x <= right and top <= y <= bottom
        if rect.4?
          emits[*] = rect.4
          if rect.4.0 is \path
            continue

        left-resolve = x - left
        right-resolve = right - x
        top-resolve = y - top
        bottom-resolve = bottom - y
        min = Math.min left-resolve, right-resolve, top-resolve, bottom-resolve
        switch
        | left-resolve is min => x = left
        | right-resolve is min => x = right
        | top-resolve is min => y = top
        | bottom-resolve is min => y = bottom

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
