require! {
  'game/effects/ParticleEmitter'
}

defs = {
  fire: {
    url: '/content/particles/orange-triangle.png'
    rate: 60
    lifetime: 10000
    alpha: (age, lifetime) ->
      d = age / lifetime
      0.6 * if d < 0.1
        d / 0.1
      else
        1 - (d - 0.1) / 0.9

    scale: (age, lifetime) ->
      0.3 * Math.sin (age/lifetime) * Math.PI

    v-x: [-0.03 0.03]
    v-y: 0
    v-r: [-0.01 0.01]
    a-x: 0
    a-y: [-0.0004 -0.0002]
    blend-mode: PIXI.BLEND_MODES.ADD
  }
}

export get-emitter = (name, emitter) ->
  name = camelize name
  if defs[name]?
    new ParticleEmitter emitter, defs[name]
  else
    throw new Error "No particle definition #name"
