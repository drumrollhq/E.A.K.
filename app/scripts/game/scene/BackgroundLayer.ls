require! {
  'game/scene/WebglLayer'
}

const tile-width = 256
  tile-height = 256

module.exports = class BackgroundLayer extends WebglLayer
  initialize: (options) ->
    super options
    @name = options.name

  load: ->
    urls = @_tile-image-urls!
    Promise.map urls, @_load-texture
      .then ~> @setup!

  setup: ->
    @container = new PIXI.DisplayObjectContainer!
    @blurable-container = new PIXI.DisplayObjectContainer!
    @tiles = []
    @blurable-tiles = []
    for x til Math.ceil @width / tile-width
      @tiles[x] = []
      @blurable-tiles[x] = []

      for y til Math.ceil @height / tile-height
        @tiles[x][y] = sprite = PIXI.Sprite.from-image @_tile-image-url x, y
        @blurable-tiles[x][y] = blurable-sprite = PIXI.Sprite.from-image @_tile-image-url x, y
        @container.add-child sprite
        @blurable-container.add-child blurable-sprite

        # sprite.texture.base-texture.resolution = 2
        sprite.position.x = blurable-sprite.position.x = x * tile-width
        sprite.position.y = blurable-sprite.position.y = y * tile-height
        sprite.width = blurable-sprite.width = tile-width
        sprite.height = blurable-sprite.height = tile-height

    @add-edge-sprites @tiles, @container
    @add-edge-sprites @blurable-tiles, @blurable-container

    @stage.add-child @blurable-container
    @stage.add-child @container
    @container.visible = false

    return

  edge-sprite: (cont, sprite, x, y, width = sprite.texture.width, height = sprite.texture.height, x-ref, y-ref) ->
    if x < 0 then x = width - x
    if y < 0 then y = height - y
    crop = new PIXI.Rectangle x, y, width, height
    tex = new PIXI.Texture sprite.texture, crop
    sprite = new PIXI.Sprite tex
    sprite.width = if typeof x-ref is \string then @width else tile-width
    sprite.height = if typeof y-ref is \string then @height else tile-height
    cont.add-child sprite

    if x-ref is \l then x-ref = -sprite.width
    if x-ref is \r then x-ref = @width
    if y-ref is \t then y-ref = -sprite.height
    if y-ref is \b then y-ref = @height
    sprite.position.x = x-ref
    sprite.position.y = y-ref

    sprite

  # Add sprites extending the edge-pixel of the background image
  add-edge-sprites: (grid, cont) ->
    width = grid.length
    height = grid.0.length
    tl-corner = @edge-sprite cont, grid.0.0, 0, 0, 1, 1, \l \t
    tr-corner = @edge-sprite cont, grid[width - 1].0, -1, 0, 1, 1, \r \t
    bl-corner = @edge-sprite cont, grid.0[height - 1], 0, -1, 1, 1, \l \b
    br-corner = @edge-sprite cont, grid[width - 1][height - 1], -1, -1, 1, 1, \r \b
    left-edge = [@edge-sprite cont, sprite, 0, 0, 1, null, \l, i * tile-height for sprite, i in grid.0]
    top-edge = [@edge-sprite cont, col.0, 0, 0, null, 1, i * tile-width, \t for col, i in grid]
    right-edge = [@edge-sprite cont, sprite, -1, 0, 1, null, \r, i * tile-height for sprite, i in grid[width - 1]]
    bottom-edge = [@edge-sprite cont, col[height - 1], 0, -1, null, 1, i * tile-width, \b for col, i in grid]

    grid.unshift left-edge
    grid.push right-edge
    top-edge.unshift tl-corner
    top-edge.push tr-corner
    bottom-edge.unshift bl-corner
    bottom-edge.push br-corner
    for col, i in grid
      col.unshift top-edge[i]
      col.push bottom-edge[i]

  render: ->
    # hide tiles that aren't visible
    const pad = 10px
    for x til @tiles.length
      for y til @tiles[x].length
        xc = (x - 1) * tile-width
        yc = (y - 1) * tile-height
        @tiles[x][y].visible = @blurable-tiles[x][y].visible =
          @left - tile-width - pad <= xc <= @right + pad and
          @top - tile-height - pad <= yc <= @bottom + pad

    super!

  focus: (rect, duration) ->
    @_focus-mask = new PIXI.Graphics!
      ..begin-fill 0xFF00FF
      ..draw-rect rect.left, rect.top, rect.width, rect.height
      ..end-fill!

    @stage.add-child @_focus-mask
    @container.mask = @_focus-mask
    @container.visible = true

    @_blur-filter = new PIXI.BlurFilter!
      ..blur = 0
    @blurable-container.filters = [@_blur-filter]
    @render!
    @animate duration, (amt) ~> @_blur-filter.blur = 30 * amt

  unfocus: (duration) ->
    @animate duration, (amt) ~> @_blur-filter.blur = 30 * (1 - amt)
      .then ~>
        @container.mask = null
        @container.visible = false
        @stage.remove-child @_focus-mask
        @_focus-mask = null
        @blurable-container.filters = null
        @_blur-filter = null
        @render!

  _tile-image-urls: (suffix = '') ->
    x-tiles = Math.ceil @width / tile-width
    y-tiles = Math.ceil @height / tile-height
    [@_tile-image-url x, y, suffix for x til x-tiles for y til y-tiles]

  _tile-image-url: (x, y, suffix = '') ->
    "/content/bg-tiles/#{@name}#suffix.t#x-#y.png?_v=#{EAKVERSION}"

  _load-texture: (url) -> new Promise (resolve, reject) ~>
    texture = PIXI.Texture.from-image url, false
    if texture.base-texture.has-loaded
      resolve texture
    else
      texture.base-texture.on \loaded, -> resolve texture
      texture.base-texture.on \error, -> reject "Error loading sprite #url"
