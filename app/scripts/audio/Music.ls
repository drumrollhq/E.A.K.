require! {
  'audio/context'
  'audio/Sound'
  'audio/Track'
}

track = new Track 'music'

module.exports = class Music
  (@name, @_layers) ->
    @playing = false

  load: (cb) ~>
    layers = [{name: key, path: value} for key, value of @_layers]
    err, layers <~ async.map layers, (layer, cb) ->
      sound = new Sound layer.path, track
      sound.loop = true
      err <- sound.load

      cb err, {name: layer.name, sound}

    if err then return cb err
    @layers = {[layer.name, layer.sound] for layer in layers}
    cb!

  play: (name, offset = 0) ->
    if @playing then return
    layer = @layers[name]
    unless layer? then throw new Error 'No layer called ' + name

    @playing-sound = layer.start context.current-time, offset
    @playing = name

  stop: ->
    @playing-sound.stop!
    @playing = false

  switch-to: (name) ->
    if not @playing then return
    offset = context.current-time - @playing-sound.started
    @stop!
    @play name, offset

  fade-to: (name, duration = 5) ->
    if (not @playing) or (@playing is name) then return
    new-layer = @layers[name]
    unless new-layer? then throw new Error 'No layer called ' + name
    old-layer = @layers[@playing]
    old-sound = @playing-sound

    offset = context.current-time - old-sound.started

    # Fade out and stop the old layer:
    console.log 1
    old-layer.gain.set-value-at-time 1, context.current-time
    console.log 2
    old-layer.gain.linear-ramp-to-value-at-time 0, context.current-time + duration
    console.log 3
    old-sound.stop context.current-time + duration
    console.log 4

    # Fade in the new layer
    new-layer.gain.set-value-at-time 0, context.current-time
    console.log 5
    new-layer.gain.linear-ramp-to-value-at-time 1, context.current-time + duration
    console.log 6
    new-sound = new-layer.start context.current-time, offset
    console.log 7

    @playing-sound = new-sound
    @playing = name
