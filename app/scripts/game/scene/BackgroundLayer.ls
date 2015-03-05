require! {
  'game/scene/WebglLayer'
}

const tile-width = 512
  tile-height = 512

module.exports = class BackgroundLayer extends WebglLayer
  initialize: (options) ->
    super options
    @name = options.name

  load: ->
    urls = @_tile-image-urls! ++ @_tile-image-urls '.blur'
    Promise.map urls, @_load-texture
      .then ~> @setup!

  setup: ->
    @container = new PIXI.SpriteBatch!
    @blurred-container = new PIXI.SpriteBatch!
    @tiles = []
    @blurred-tiles = []
    for x til Math.ceil @width / tile-width
      @tiles[x] = []
      @blurred-tiles[x] = []

      for y til Math.ceil @height / tile-height
        @tiles[x][y] = sprite = PIXI.Sprite.from-image @_tile-image-url x, y
        @blurred-tiles[x][y] = blurred-sprite = PIXI.Sprite.from-image @_tile-image-url x, y, '.blur'
        @container.add-child sprite
        @blurred-container.add-child blurred-sprite

        sprite.texture.base-texture.resolution = blurred-sprite.texture.base-texture.resolution = 2
        sprite.position.x = blurred-sprite.position.x = x * tile-width
        sprite.position.y = blurred-sprite.position.y = y * tile-height
        sprite.width = tile-width
        sprite.height = tile-height

    @stage.add-child @container
    @stage.add-child @blurred-container
    @blurred-container.visible = false

    return

  render: ->
    # hide tiles that aren't visible
    const pad = 10px
    for x til @tiles.length
      for y til @tiles[x].length
        xc = x * tile-width
        yc = y * tile-height
        @tiles[x][y].visible = @blurred-tiles[x][y].visible =
          @left - tile-width - pad <= xc <= @right + pad and
          @top - tile-height - pad <= yc <= @bottom + pad

    super!

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
