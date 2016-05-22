require! {
  'assets'
  'game/actors/Actor'
}

module.exports = class FadingPanel extends Actor
  @from-el = ($el, [type = \show, speed], offset, save-level, area-view) ->
    bg = $el.attr \data-layer-background or null
    effects = $el.attr \data-layer-effects or null
    speed = if speed then parse-int speed else 200ms

    new FadingPanel {
      el: $el
      type: type
      speed: speed
      offset: offset
      store: save-level
      area-view: area-view
      layers:
        background: bg
        effects: effects
    }

  physics: data:
    dynamic: false
    sensor: true

  mapper-ignore: false

  initialize: (options) ->
    super options
    @display-type = options.type
    @speed = options.speed
    @layers = options.layers
    @area-view = options.area-view
    delete @layers.background unless @layers.background
    delete @layers.effects unless @layers.effects
    @listen-to this, \contact:start:ENTITY_PLAYER, if @display-type is \show then @show else @hide
    @listen-to this, \contact:end:ENTITY_PLAYER, if @display-type is \show then @hide else @show
    @_last-anim = Promise.resolve!

  load: ->
    if @layers.background
      url = assets.load-asset @layers.background, \url
      @background = PIXI.Sprite.from-image url
      @area-view.background-layer.add @background

    if @layers.effects
      url = assets.load-asset @layers.effects, \url
      @effects = PIXI.Sprite.from-image url
      @area-view.effects-layer.add @effects

  on-prepare: ->
    if @_already-prepared then return
    if @background then @_prepare @background
    if @effects then @_prepare @effects
    @_already-prepared = true

  _prepare: (sprite) ->
    sprite.position <<< @bounds.original.{x: left, y: top}
    sprite <<< @bounds.original.{width, height}
    sprite.visible = @display-type isnt \show

  show: ~>
    @_last-anim = @_last-anim.then ~>
      b = if @background then @_show that
      e = if @effects then @_show that
      b or e

  _show: (sprite) ->
    sprite.visible = true
    sprite.alpha = 0
    sprite.animate @speed, (t) -> sprite.alpha = t

  hide: ~>
    @_last-anim = @_last-anim.then ~>
      b = if @background then @_hide that
      e = if @effects then @_hide that
      b or e

  _hide: (sprite) ->
    sprite.alpha = 1
    sprite.animate @speed, (t) -> sprite.alpha = 1 - t
      .then -> sprite.visible = false
