require! {
  'audio/Sound'
  'audio/Track'
}

track = new Track \conversation

sounds = {}

module.exports = play-conversation-line = (root, name) ->
  path = "#root/#name"
  if sounds[path]
    sounds[path].play!
  else
    sound = sounds[path] = new Sound path, track
    sound.load!.then -> sound.play!
