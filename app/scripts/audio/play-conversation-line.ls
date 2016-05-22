require! {
  'audio/Sound'
  'audio/Track'
}

track = new Track \conversation

sounds = {}
currently-playing = null

module.exports = play-conversation-line = (root, name) ->
  path = if name then "#root/#name" else root
  console.log 'play' path
  play-conversation-line.stop!
  if sounds[path]
    currently-playing := sounds[path]
    sounds[path].play!
  else
    sound = sounds[path] = new Sound path, track
    currently-playing := sound
    sound.load!
      .cancellable!
      .then -> sound.play!
      .tap -> currently-playing := null
      .catch Promise.CancellationError, ->
        play-conversation-line.stop!
        currently-playing := null

play-conversation-line.stop = ->
  currently-playing.stop! if currently-playing
