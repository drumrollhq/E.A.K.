require! {
  'audio/Sound'
  'audio/Track'
  'audio/context'
  'audio/on-ended'
}

unless Track then return module.exports = class MockMusic
  -> @playing = false
  load: -> Promise.resolve!
  play: -> null
  stop: -> null
  fade-out: (d) -> Promise.resolve!
  switch-to: -> null
  fade-to: -> null

track = new Track 'music'

module.exports = class Music
  (@name, @_layers) ->
    @playing = false

  load: ~>
    layers = [{name: key, path: value} for key, value of @_layers]
    Promise
      .map layers, (layer) ->
        sound = new Sound layer.path, track
        sound.loop = true
        sound.load! .then -> [layer.name, sound]
      .then (layers) ~> @layers = pairs-to-obj layers

  play: (name, offset = 0) ~>
    if @playing then return
    layer = @layers[name]
    unless layer? then throw new Error 'No layer called ' + name

    @playing-sound = layer.start context.current-time, offset
    @playing = name

  stop: ~>
    @playing-sound.stop!
    @playing = false

  fade-out: (duration = 1) ~> new Promise (resolve) ~>
    layer = @layers[@playing]
    layer.gain.set-value-at-time 1, context.current-time
    layer.gain.linear-ramp-to-value-at-time 0, context.current-time + duration
    @playing-sound.on-ended = on-ended duration, resolve
    @playing-sound.stop context.current-time + duration

  switch-to: (name) ~>
    if not @playing then return
    offset = context.current-time - @playing-sound.started
    @stop!
    @play name, offset

  fade-to: (name, duration = 5) ~>
    if (not @playing) or (@playing is name) then return
    new-layer = @layers[name]
    unless new-layer? then throw new Error 'No layer called ' + name
    old-layer = @layers[@playing]
    old-sound = @playing-sound

    offset = context.current-time - old-sound.started

    # Fade out and stop the old layer:
    old-layer.gain.set-value-at-time 1, context.current-time
    old-layer.gain.linear-ramp-to-value-at-time 0, context.current-time + duration
    old-sound.stop context.current-time + duration

    # Fade in the new layer
    new-layer.gain.set-value-at-time 0, context.current-time
    new-layer.gain.linear-ramp-to-value-at-time 1, context.current-time + duration
    new-sound = new-layer.start context.current-time, offset

    @playing-sound = new-sound
    @playing = name
