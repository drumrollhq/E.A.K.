const tile-width = 256px
  tile-height = 256px

module.exports = class TiledSpriteContainer extends PIXI.Container
  (base-url, img-width, img-height) ->
    super!
    @ <<< {base-url, img-width, img-height}

  load: ->
    urls = @_tile-image-urls!
    Promise.map urls, PIXI.load-texture
      .then ~> @setup!

  setup: ->
    @tiles = []
    for x til Math.ceil @img-width / tile-width
      @tiles[x] = []
      for y til Math.ceil @img-height / tile-height
        @tiles[x][y] = sprite = new PIXI.Sprite.from-image @_tile-image-url x, y
        @add-child sprite
        sprite.position.x = x * tile-width
        sprite.position.y = y * tile-height
        sprite.width = tile-width
        sprite.height = tile-height

    @add-edge-sprites @tiles

  set-viewport: (left, top, right, bottom) ->
    const pad = 10px
    for x til @tiles.length
      for y til @tiles[x].length
        xc = (x - 1) * tile-width
        yc = (y - 1) * tile-height
        @tiles[x][y].visible =
          left - tile-width - pad <= xc <= right + pad and
          top - tile-height - pad <= yc <= bottom + pad

  # Add sprites extending the edge-pixel of the background image
  add-edge-sprites: (grid) ->
    console.log 'add-edge-sprites' grid
    width = grid.length
    height = grid.0.length
    tl-corner = @edge-sprite grid.0.0, 0, 0, 1, 1, \l \t
    tr-corner = @edge-sprite grid[width - 1].0, -1, 0, 1, 1, \r \t
    bl-corner = @edge-sprite grid.0[height - 1], 0, -1, 1, 1, \l \b
    br-corner = @edge-sprite grid[width - 1][height - 1], -1, -1, 1, 1, \r \b
    left-edge = [@edge-sprite sprite, 0, 0, 1, null, \l, i * tile-height for sprite, i in grid.0]
    top-edge = [@edge-sprite col.0, 0, 0, null, 1, i * tile-width, \t for col, i in grid]
    right-edge = [@edge-sprite sprite, -1, 0, 1, null, \r, i * tile-height for sprite, i in grid[width - 1]]
    bottom-edge = [@edge-sprite col[height - 1], 0, -1, null, 1, i * tile-width, \b for col, i in grid]

    grid.unshift left-edge
    grid.push right-edge
    top-edge.unshift tl-corner
    top-edge.push tr-corner
    bottom-edge.unshift bl-corner
    bottom-edge.push br-corner
    for col, i in grid
      col.unshift top-edge[i]
      col.push bottom-edge[i]

  edge-sprite: (sprite, x, y, width = sprite.texture.width, height = sprite.texture.height, x-ref, y-ref) ->
    if x < 0 then x = width - x
    if y < 0 then y = height - y
    crop = new PIXI.math.Rectangle x, y, width, height
    tex = new PIXI.Texture sprite.texture, crop
    sprite = new PIXI.Sprite tex
    sprite.width = if typeof x-ref is \string then @img-width else tile-width
    sprite.height = if typeof y-ref is \string then @img-height else tile-height
    @add-child sprite

    if x-ref is \l then x-ref = -sprite.width
    if x-ref is \r then x-ref = @img-width
    if y-ref is \t then y-ref = -sprite.height
    if y-ref is \b then y-ref = @img-height
    sprite.position.x = x-ref
    sprite.position.y = y-ref

    sprite

  _tile-image-urls: ->
    x-tiles = Math.ceil @img-width / tile-width
    y-tiles = Math.ceil @img-height / tile-height
    [@_tile-image-url x, y for x til x-tiles for y til y-tiles]

  _tile-image-url: (x, y) ->
    "#{@base-url}.t#{x}-#{y}.png?_v=#{EAKVERSION}"
