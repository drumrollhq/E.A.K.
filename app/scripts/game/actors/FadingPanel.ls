require! {
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
    Promise.map (values @layers), PIXI.load-texture
      .then ~>
        if @layers.background
          @background = PIXI.Sprite.from-image @layers.background
          @area-view.background-layer.add @background

        if @layers.effects
          @effects = PIXI.Sprite.from-image @layers.effects
          @area-view.effects-layer.add @effects

  on-prepare: ->
    console.log \FadingPanel \prepare
    if @background then @_prepare @background
    if @effects then @_prepare @effects

  _prepare: (sprite) ->
    sprite.anchor <<< {x: 0.5, y: 0.5}
    sprite.position <<< @p.{x, y}
    sprite <<< @{width: actual-width, height: actual-height}
    console.log \display-type @display-type
    sprite.visible = @display-type isnt \show

  show: ~>
    @_last-anim = @_last-anim.then ~>
      (if @background then @_show that) or
        (if @effects then @_show that)

  _show: (sprite) ->
    sprite.visible = true
    sprite.alpha = 0
    sprite.animate @speed, (t) -> sprite.alpha = t

  hide: ~>
    @_last-anim = @_last-anim.then ~>
      (if @background then @_hide that) or
        (if @effects then @_hide that)

  _hide: (sprite) ->
    sprite.alpha = 1
    sprite.animate @speed, (t) -> sprite.alpha = 1 - t
      .then -> sprite.visible = false
