require! {
  'audio/Sound'
  'audio/Track'
  'lib/channels'
  'translations'
}

unless Track then return module.exports = new class MockEffects
  -> @ready = false
  play: -> null
  load: ~>
    @ready = true
    Promise.resolve!

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

  load: ~>
    files = [{name: key, path: value} for key, value of @_files]
    Promise
      .map files, (file) ->
        sound = new Sound file.path, track
        sound.load! .then -> [file.name, sound]
      .then (sounds) ~>
        @_sounds = pairs-to-obj sounds
        @ready = true

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
    'kitten': \box-get
    'game-commands: portal': \portal
    'death': \player-death
    'game-commands: edit': \edit-start
    'game-commands: stop-edit': \edit-stop
}
