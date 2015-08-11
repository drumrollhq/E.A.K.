exports, require, module <- require.register 'minigames/urls/WalkingMap'

require! {
  'assets'
  'game/scene/TiledSpriteContainer'
  'lib/keys'
}

const player-speed = 0.3px
const player-scale = 0.4

const draw-hit-rects = false
colors = [0xFF0000 0x00FF00 0x0000FF 0x00FFFF 0xFF00FF 0xFFFF00]

module.exports = class WalkingMap extends PIXI.Container
  (@layer, @player, {width, height, map-url, @start, @rects}) ->
    super!
    @bg = new TiledSpriteContainer map-url, width, height, false
    @add-child @bg

    if draw-hit-rects
      @dbg = new PIXI.Graphics!
      @dbg-labels = []
      @add-child @dbg

  setup: ->
    @bg.setup!

  step: (t) ->
    unless @active then return
    if keys.up
      @player.y -= player-speed * t
    else if keys.down
      @player.y += player-speed * t

    if keys.right
      @player.x += player-speed * t
    else if keys.left
      @player.x -= player-speed * t

    if draw-hit-rects
      @dbg.clear!
      for rect, i in @rects
        unless @dbg-labels[i]
          @dbg-labels[i] = new PIXI.Text "rects[#{i}]", fill: colors[i % colors.length], font: '12px Arial'
          @add-child @dbg-labels[i]

        @dbg-labels[i] <<< x: rect.0, y: rect.1, text: "rects[#{i}] #{if rect.4 then "(#{rect.4})" else ''}"
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

      if left < x < right and top < y < bottom
        if rect.4?
          emits[*] = "hit:#{rect.4}"

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
    for emit in emits => @emit emit

  set-viewport: (top, left, bottom, right) ->
    @bg.set-viewport top, left, bottom, right

  activate: ->
    @active = true

  deactivate: ->
    @active = false
