require! {
  'audio/Music'
  'lib/channels'
}

tracks = {
  forest:
    normal: '/audio/music/forest'
    glitch: '/audio/music/forest-glitch'

  cave:
    normal: '/audio/music/cave'
    glitch: '/audio/music/cave-glitch'

  space:
    normal: '/audio/music/space'
    glitch: '/audio/music/space-glitch'

  beach:
    normal: '/audio/music/beach'
    glitch: '/audio/music/beach-glitch'

  colours:
    normal: '/audio/music/colours'
    glitch: '/audio/music/colours-glitch'

  spaceship:
    normal: '/audio/music/spaceship-normal'
    glitch: '/audio/music/spaceship-normal'
    disco: '/audio/music/spaceship-disco'
    disco-glitch: '/audio/music/spaceship-disco'
    creepy: '/audio/music/spaceship-creepy'
    creepy-glitch: '/audio/music/spaceship-creepy'
}

const fade-duration = 0.75s

class MusicManager
  (@tracks) ->
    @tracks.none = false
    @playing = false

  start-track: (name) ~>
    unless @tracks[name]? then throw new Error 'Cannot find track called ' + name
    if @playing is name then return Promise.resolve!
    @playing = name

    if name is \none then return @stop!

    music = new Music name, @tracks[name]
    Promise.all [music.load!, @stop!]
      .then ~>
        music.play \normal
        @music = music

  stop: ~>
    unless @music then return Promise.resolve!
    music = @music
    @music = null
    music.fade-out fade-duration

  switch-track: (track) ~>
    unless @music? then return
    @music.fade-to track, fade-duration

module.exports = new MusicManager tracks
