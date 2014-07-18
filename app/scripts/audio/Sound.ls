require! {
  'channels'
  'audio/context'
  'audio/load'
}

module.exports = class Sound
  (@_path, @_track) ->

  load: (cb) ~>
    buffer, err <~ load @_path
    if err then return cb err
    @_buffer = buffer
    cb!

  start: ~>
    sound-source = context.create-buffer-source!
    sound-source.buffer = @_buffer
    sound-source.connect @_track.node
    sound-source.onended = ~> sound-source.disconnect @_track.node
    sound-source.start 0, 0, @_buffer.duration
    sound-source
