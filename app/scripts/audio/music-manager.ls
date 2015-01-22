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
}

class MusicManager
  (@tracks) ->
    @tracks.none = false
    @playing = false
    @_setup-triggers!

  _setup-triggers: ->
    channels.parse 'game-commands: edit-start' .subscribe ~> @switch-track 'glitch'
    channels.parse 'game-commands: edit-stop' .subscribe ~> @switch-track 'normal'

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
    music.fade-out 0.5

  switch-track: (track) ~>
    unless @music? then return
    @music.fade-to track, 0.5

module.exports = new MusicManager tracks
