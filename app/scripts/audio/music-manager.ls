require! {
  'audio/Music'
  'channels'
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

const none = 'none'
const normal = 'normal'

class MusicManager
  (@tracks) ->
    @tracks.none = false
    @playing = false
    @_setup-triggers!

  _setup-triggers: ->
    channels.parse 'game-commands: edit-start' .subscribe ~> @switch-track 'glitch'
    channels.parse 'game-commands: edit-stop' .subscribe ~> @switch-track 'normal'

  start-track: (name, cb = ->) ~>
    unless @tracks[name]? then throw new Error 'Cannot find track called ' + name
    if @playing is name then return cb!
    @playing = name

    if name is none then return @stop cb

    music = new Music name, @tracks[name]
    err <~ async.parallel [music.load, @stop]

    if err?
      channels.alert.publish msg: "#{translations.errors.music-not-found}: #err"
      return cb!


    music.play normal
    @music = music
    cb!

  stop: (cb) ~>
    unless @music then return cb!
    @music.fade-out 0.5, cb
    @music = null

  switch-track: (track) ~>
    unless @music? then return
    @music.fade-to track, 0.5


module.exports = new MusicManager tracks
