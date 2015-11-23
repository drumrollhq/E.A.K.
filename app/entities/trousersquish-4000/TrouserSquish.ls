require! {
  'game/actors/Actor'
  'game/effects/Image'
  'game/effects/ParticleEmitter'
  'game/effects/SpriteSheet'
  'lib/channels'
  'lib/math/Vector'
  'lib/math/ease'
}

steam = {
  url: '/content/particles/white-hex.png'
  rate: 30
  lifetime: 1500
  alpha: (age, lifetime) -> 0.5 * ease.sin-arch-midpoint age / lifetime, 0.2
  scale: (age, lifetime) -> 0.05 + 0.5 * ease.sin age / lifetime
  v-x: [0.6 0.9]
  v-y: 0
  v-r: [-0.05 0.05]
  a-x: 0
  a-y: [-0.04, -0.02]
  blend-mode: PIXI.BLEND_MODES.OVERLAY
}

class TrouserSquish extends Actor
  physics: {
    data:
      dynamic: true
      ignore-others: true
  }

  mapper-ignore: false

  initialize: (options) ->
    super options
    @render!
    @timer = @_last-y = @_current-y = 0
    window.squish = this
    @listen-to this, 'contact:start:ENTITY_PLAYER', @check-squish

  render: ->
    @$el.add-class \trousersquish-4000

  load: ->
    @bubbles = new SpriteSheet '/entities/trousersquish-4000/assets/trousersquish-bubbles', 280, 168, @x, @y
    @dial = new SpriteSheet '/entities/trousersquish-4000/assets/trousersquish-dial', 280, 168, @x, @y
    @top-wobble = new SpriteSheet '/entities/trousersquish-4000/assets/top-wobble', 280, 168, @x, @y
    Promise.all [@bubbles.load!, @dial.load!, @top-wobble.load!]

  on-prepare: ->
    @offset <<< x: 0, y: 0

    if @_prepared
      @x = @start-x
      @y = @start-y
      return

    @_prepared = true

    @start-x = @x
    @start-y = @y

    @back = new Image '/entities/trousersquish-4000/assets/back.png', 200, 127, @x - 100, @y + 68
    @area-view.background-layer.add @back

    @front = new Image '/entities/trousersquish-4000/assets/front.png', 280, 286, @x - 141, @y - 91
    @area-view.effects-layer.add @front

    @bubbles <<< x: @x - 141, y: @y - 91
    @dial <<< x: @x - 141, y: @y - 91
    @top-wobble <<< x: @x - 141, y: @y - 91
    @area-view.effects-layer.add @bubbles
    @area-view.effects-layer.add @dial
    @area-view.effects-layer.add @top-wobble

    @steam = new ParticleEmitter (new Vector @x + 115, @y + -45), steam
    @area-view.effects-layer.add @steam

  step: (t) ->
    @timer += t * 30
    @steam.step t
    y = 0

    if @timer < 1000
      @steam._paused = false
    else if @timer < 1300
      y = 85 * ease.sin (@timer - 1000) / 300
    else if @timer < 3000
      y = 85
    else if @timer < 4000
      @steam._paused = true
      y = 85 * (1 - ease.sin (@timer - 3000) / 1000)
    else if @timer > 6000
      @timer = 0

    @_last-y = @_current-y
    @_current-y = y
    @p.x = @start-x + @offset.x
    @p.y = @start-y + @offset.y + y

  check-squish: (player) ->
    if @_current-y > @_last-y
      channels.death.publish cause: \squish
      player.fall-to-death!

eak.register-actor TrouserSquish
