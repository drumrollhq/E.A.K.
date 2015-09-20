require! {
  'game/actors/Actor'
  'game/effects/Image'
  'game/effects/ParticleEmitter'
  'game/effects/SpriteSheet'
  'lib/math/ease'
  'lib/math/Vector'
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
      ignore-others: true
  }

  mapper-ignore: false

  initialize: (options) ->
    super options
    @render!
    window.squish = this

  render: ->
    @$el.add-class \trousersquish-4000

  load: ->
    @bubbles = new SpriteSheet '/entities/trousersquish-4000/assets/trousersquish-bubbles', 280, 168, @x, @y
    @dial = new SpriteSheet '/entities/trousersquish-4000/assets/trousersquish-dial', 280, 168, @x, @y
    Promise.all [@bubbles.load!, @dial.load!]

  on-prepare: ->
    @back = new Image '/entities/trousersquish-4000/assets/back.png', 200, 127, @x - 100, @y - 7
    @area-view.background-layer.add @back

    @front = new Image '/entities/trousersquish-4000/assets/front.png', 280, 286, @x - 141, @y - 166
    @area-view.effects-layer.add @front

    @bubbles <<< x: @x - 141, y: @y - 166
    @dial <<< x: @x - 141, y: @y - 166
    @area-view.effects-layer.add @bubbles
    @area-view.effects-layer.add @dial

    @steam = new ParticleEmitter (new Vector @x + 115, @y - 120), steam
    @area-view.effects-layer.add @steam

  after-physics: (t) ->
    @steam.step t

eak.register-actor TrouserSquish
