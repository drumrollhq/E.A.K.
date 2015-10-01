require! {
  'audio/context'
  'audio/load'
  'lib/channels'
}

module.exports = class Sound
  (@_path, track) ->
    @loop = false
    @gain-node = context.create-gain!
    @gain-node.connect track.node
    @gain = @gain-node.gain

  load: ~>
    load @_path .then (buffer) ~> @_buffer = buffer

  start: (when_ = context.current-time, offset = 0, duration = void) ~>
    if duration then duration = duration % @_buffer.duration

    sound-source = context.create-buffer-source!
      ..buffer = @_buffer
      ..connect @gain-node
      ..on-ended = -> null
      ..onended = ~>
          sound-source.disconnect!
          sound-source.on-ended!
          @_playing = false
      ..loop = @loop

    if duration
      sound-source.start when_, offset % @_buffer.duration, duration
    else sound-source.start when_, offset % @_buffer.duration

    sound-source.started = context.current-time - offset
    @_playing = true
    sound-source

  play: -> new Promise (resolve) ~>
    if @_playing then return resolve!
    @start! .on-ended = ~> resolve!

