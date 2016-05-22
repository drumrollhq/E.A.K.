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
    @track-name = name
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

  switch-to: (track-name) ~>
    name = @get-name track-name
    if not @playing then return
    offset = context.current-time - @playing-sound.started
    @stop!
    @track-name = track-name
    @play name, offset

  fade-to: (track-name, duration = 5) ~>
    name = @get-name track-name
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
    @track-name = track-name
    @playing = name

  get-name: (name) ->
    if @_glitched
      if @_layers["#{name}Glitch"] then "#{name}Glitch" else \glitch
    else
      name

  glitchify: (duration) ->
    if @_glitched then return
    @_glitched = true
    @fade-to @track-name, duration

  deglitchify: (duration) ->
    unless @_glitched then return
    @_glitched = false
    @fade-to @track-name, duration
