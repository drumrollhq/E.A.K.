require! {
  'game/effects/ParticleEmitter'
}

defs = {
  fire: {
    url: '/content/particles/orange-triangle.png'
    rate: 1
    lifetime: 9000
    alpha: (age, lifetime) ->
      midpoint = 0.2
      d = age / lifetime
      if d < midpoint
        Math.sin (Math.PI/2) * (d/midpoint)
      else
        Math.sin ((d + 1 - midpoint*2) / (1 - midpoint)) * Math.PI / 2

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
