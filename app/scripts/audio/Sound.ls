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
      # According to https://code.google.com/p/chromium/issues/detail?id=349543, onended handlers
      # are incorrectly GCd due to a bug in chrome. Here, never-gc stores the event handler on
      # window, stopping it from getting GCd but also creating a memory leak. Sigh.
      ..onended = never-gc ~>
          sound-source.disconnect!
          sound-source.on-ended!
          @_playing = false
      ..loop = @loop

    if duration
      sound-source.start when_, offset % @_buffer.duration, duration
    else sound-source.start when_, offset % @_buffer.duration

    sound-source.started = context.current-time - offset
    @_playing = true
    @_playing-source = sound-source
    sound-source

  play: -> new Promise (resolve) ~>
    if @_playing then return resolve!
    @start! .on-ended = ~> resolve!

  stop: -> @_playing-source.stop! if @_playing-source
