require! {
  'game/actors/Mover'
  'game/effects/ParticleEmitter'
  'lib/math/Vector'
}

particle-def = {
  url: '/content/particles/electric-spark.png'
  rate: [3 10]
  lifetime: [100 500]
  v-x: [-4 4]
  v-y: [-5 2]
  a-x: 0
  a-y: [0.2 0.3]
  alpha: (age, lifetime) -> 1 - age/lifetime

  scale: [0.2 0.5]
}

class RicketySpacePlatform extends Mover
  load: ->
    @emitter = new ParticleEmitter new Vector!, particle-def
    @emitter.load!.then ~>
      @area-view.background-layer.stage.add-child @emitter

  step: (t) ->
    super t
    @emitter
      ..step t
      ..emitter.x = @p.x
      ..emitter.y = @p.y - 20px

eak.register-actor RicketySpacePlatform
