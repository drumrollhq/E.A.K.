require! {
  'game/effects/ParticleEmitter'
}

defs = {
}

export get-emitter = (name, emitter) ->
  name = camelize name
  if defs[name]?
    new ParticleEmitter emitter, defs[name]
  else
    throw new Error "No particle definition #name"
