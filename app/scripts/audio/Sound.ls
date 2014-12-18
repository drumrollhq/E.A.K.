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

  load: (cb) ~>
    buffer, err <~ load @_path
    if err then return cb err
    @_buffer = buffer
    cb!

  start: (wh = context.current-time, offset = 0, duration) ~>
    unless duration? then duration = @_buffer.duration - (offset % @_buffer.duration)

    sound-source = context.create-buffer-source!
      ..buffer = @_buffer
      ..connect @gain-node
      ..on-ended = -> null
      ..onended = ~>
          sound-source.disconnect!
          sound-source.on-ended!
      ..loop = @loop
      ..start wh, offset % @_buffer.duration, duration
      ..started = context.current-time - offset
