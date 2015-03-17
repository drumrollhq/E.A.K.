require! {
  'game/effects/ParticleEmitter'
}

defs = {
  space-pulse: {
    url: '/content/particles/space-pulse.png'
    rate: 50
    lifetime: 1000ms
    y: (age) -> age / 20
    scale: (age, lifetime) -> 1 - age/lifetime
    alpha: (age, lifetime) ->
      p = age / lifetime
      if p < 0.4 then p * 2.5
      else 1 - (p - 0.4) * 1.666
  }
}

export get-emitter = (name, emitter) ->
  name = camelize name
  if defs[name]?
    new ParticleEmitter emitter, defs[name]
  else
    throw new Error "No particle definition #name"
