require! {
  'game/scene/TiledSpriteContainer'
  'lib/channels'
}

module.exports = class AreaOverlay extends TiledSpriteContainer
  (name, regions, width, height) ->
    super "/content/bg-tiles/#{name}.overlay", width, height

    @mask = new PIXI.Graphics!

    @regions = for region in regions =>
      region =
        | typeof! region is \Array => {rect: region, triggers: [region]}
        | typeof! region is \Object and not region.triggers? => {rect: region.rect, triggers: [region.rect]}
        | typeof! region is \Object and typeof! region.triggers is \Object => {rect: region.rect, triggers: [region.triggers]}

    channels.player-position.subscribe ({x, y}) ~> @update x, y

  update: (x, y) ->
    @player-x = x
    @player-y = y

  draw: (left, top, right, bottom) ->
    # unless @mask
    #   @mask = new PIXI.Graphics!
    #   @add-child @mask

    width = right - left
    height = bottom - top

    @mask
      ..x = left
      ..y = top
      ..clear!
      ..begin-fill 0xFFFFFF
      ..line-style 0
      ..move-to 0, 0
      ..line-to width, 0
      ..line-to width, height
      ..line-to 0, height
      ..line-to 0, 0

    for region in @regions =>
      [x, y, width, height] = region.rect
      if x < @player-x < x + width and y < @player-y < y + height
        @mask
          ..line-to x - left, y - top
          ..line-to x - left + width, y - top
          ..line-to x - left + width, y - top + height
          ..line-to x - left, y - top + height
          ..line-to x - left, y - top
          ..line-to 0, 0

  set-viewport: (left, top, right, bottom) ->
    super left, top, right, bottom
    @draw left, top, right, bottom

