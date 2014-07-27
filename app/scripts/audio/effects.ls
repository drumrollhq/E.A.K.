require! {
  'audio/Sound'
  'audio/Track'
  'channels'
  'translations'
}

unless Track then return module.exports = new class MockEffects
  -> @ready = false
  play: -> null
  load: (cb) ~>
    @ready = true
    cb!

track = new Track 'effects'

class Effects
  ({effects, triggers}) ->
    @_files = effects
    @ready = false
    @setup-triggers triggers

  play: (name) ~>
    unless @ready then return
    sound = @_sounds[camelize name]
    unless sound? then throw new Error "#{translations.errors.sound-not-found} #name"

    sound.start!

  load: (cb) ~>
    files = [{name: key, path: value} for key, value of @_files]
    err, sounds <~ async.map files, (file, cb) ->
      sound = new Sound file.path, track
      err <- sound.load
      cb err, {name: file.name, sound}

    if err then return cb err

    @_sounds = {[sound.name, sound.sound] for sound in sounds}
    @ready = true
    cb!

  setup-triggers: (triggers) ->
    for let trigger, sound of triggers
      channels.parse trigger .subscribe ~> @play sound

module.exports = new Effects {
  effects:
    box-get: '/audio/effects/box-get'
    portal: '/audio/effects/portal'
    player-death: '/audio/effects/player-death'
    edit-start: '/audio/effects/edit-start'
    edit-stop: '/audio/effects/edit-stop'

  triggers:
    'kitten': 'box-get'
    'game-commands: portal': 'portal'
    'death': 'player-death'
    'game-commands: edit-start': 'edit-start'
    'game-commands: edit-stop': 'edit-stop'
}
