require! {
  'audio/Sound'
  'audio/Track'
}

track = new Track \conversation

sounds = {}
currently-playing = null

module.exports = play-conversation-line = (root, name) ->
  path = "#root/#name"
  play-conversation-line.stop!
  if sounds[path]
    sounds[path].play!
  else
    sound = sounds[path] = new Sound path, track
    currently-playing := sound
    sound.load!
      .then -> sound.play!
      .tap -> currently-playing := null

play-conversation-line.stop = ->
  currently-playing.stop! if currently-playing
