require! {
  'game/actors/Mover'
  'game/effects/ParticleEmitter'
  'lib/math/Vector'
}

particle-def = {
  url: '/content/particles/space-pulse.png'
  rate: [15 20]
  lifetime: [100 150]
  y: (age) -> age / 5
  scale: (age, lifetime) -> 0.3 + 0.3 * (age/lifetime)
  alpha: (age, lifetime) ->
    p = age / lifetime
    if p < 0.4 then p * 2.5
    else 1 - (p - 0.4) * 1.666
}

class SpacePlatform extends Mover
  load: ->
    @emitters = [
      new ParticleEmitter new Vector!, particle-def
      new ParticleEmitter new Vector!, particle-def
      new ParticleEmitter new Vector!, particle-def
    ]

    Promise.map @emitters, (emitter) ~>
      emitter.load! .then ~>
        @area-view.effects-layer.add emitter

  step: (t) ->
    super t
    for emitter, i in @emitters
      emitter.step t
      emitter.emitter.x = @p.x + (i - 1) * 37px
      emitter.emitter.y = @p.y + 10px

eak.register-actor SpacePlatform
