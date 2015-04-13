require! {
  'game/scene/TiledSpriteContainer'
  'lib/channels'
}

const fade-speed = 0.1

module.exports = class AreaOverlay extends TiledSpriteContainer
  @DRAW_TRIGGERS = false

  (name, regions, width, height, renderer) ->
    super "/content/bg-tiles/#{name}.overlay", width, height

    @render-texture = new PIXI.RenderTexture renderer, 100, 100

    @regions = for region in regions =>
      region =
        | typeof! region is \Array => {rect: region, triggers: [region]}
        | typeof! region is \Object and not region.triggers? => {rect: region.rect, triggers: [region.rect]}
        | typeof! region is \Object and typeof! region.triggers is \Array => {rect: region.rect, triggers: region.triggers}
        | otherwise => throw new Error "Bad region format: #{JSON.stringify region}"

    @create-mask-graphics!
    @main-mask = @create-main-mask!

    channels.player-position.subscribe ({x, y}) ~> @update x, y

  create-mask-graphics: ->
    for region in @regions
      [x, y, width, height] = region.rect
      region.graphics = new PIXI.Graphics!
        ..line-style 0
        ..begin-fill 0xFFFFFF
        ..draw-rect 0, 0, width, height
        ..x = x
        ..y = y

  update: (x, y) ->
    @player-x = x
    @player-y = y

  draw: (left, top, right, bottom) ->
    unless @mask
      @cont = new PIXI.Container!
      @cont.add-child @main-mask
      for region in @regions => @cont.add-child region.graphics

      @render-cont = new PIXI.Container!
      @render-cont.add-child @cont
      @render-texture.render @render-cont
      @mask = new PIXI.Sprite @render-texture

      if AreaOverlay.DRAW_TRIGGERS
        @draw-triggers!

    @cont <<< {x: -left, y: -top}

    for region in @regions
      if @in-triggers region.triggers
        if region.graphics.alpha > 0
          region.graphics.alpha -= fade-speed
          region.graphics.alpha = 0 if region.graphics.alpha < 0

      else if region.graphics.alpha < 1
        region.graphics.alpha += fade-speed
        region.graphics.alpha = 1 if region.graphics.alpha > 1

    @render-texture
      ..clear!
      ..render @render-cont

  draw-triggers: ->
    colors = [0xFF0000, 0xFFFF00, 0x00FF00, 0x00FFFF, 0x0000FF, 0xFF00FF]
    unless @_dbg-draw
      @_dbg-draw = new PIXI.Graphics!
      eak.view.effects-layer.add @_dbg-draw, 5

    for region, i in @regions
      @_dbg-draw.line-style 1, colors[i % colors.length]
      for [x, y, width, height] in region.triggers
        @_dbg-draw.draw-rect x, y, width, height

  set-viewport: (left, top, right, bottom) ->
    super left, top, right, bottom

    width = right - left
    height = bottom - top
    if width isnt @render-texture.width or height isnt @render-texture.height
      @render-texture.resize width, height, true
      @render-texture.renderer.resize width, height

    @draw left, top, right, bottom

  create-main-mask: (width, height) ->
    graphics = new PIXI.Graphics!
      ..begin-fill 0xFFFFFF
      ..line-style 0
      ..move-to 0, 0
      ..line-to @img-width, 0
      ..line-to @img-width, @img-height
      ..line-to 0, @img-height
      ..line-to 0, 0

    for region in @regions
      [x, y, width, height] = region.rect
      graphics
        ..line-to x, y
        ..line-to x + width, y
        ..line-to x + width, y + height
        ..line-to x, y + height
        ..line-to x, y
        ..line-to 0, 0

    graphics

  in-triggers: (triggers) ->
    {player-x, player-y} = @
    for rect in triggers
      [x, y, width, height] = rect
      if x < player-x < x + width and y < player-y < y + height
        return true

    return false
