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

  start: (wh = context.current-time, offset = 0, duration) ~>
    unless duration? then duration = @_buffer.duration - (offset % @_buffer.duration)

    stopped = false
    sound-source = context.create-buffer-source!
      ..buffer = @_buffer
      ..connect @gain-node
      ..on-ended = -> null
      ..onended = ~>
          # console.log 'onended. continue?:', (@loop and not stopped)
          # if @loop and not stopped then return
          sound-source.disconnect!
          sound-source.on-ended!
      ..loop = @loop
      ..start wh, offset % @_buffer.duration, duration
      ..started = context.current-time - offset

    # sound-source._stop = sound-source.stop
    # sound-source.stop = ->
    #   stopped := true
    #   sound-source._stop!
