require! {
  'game/actors/Actor'
  'lib/channels'
}

class Water extends Actor
  physics: data:
    dynamic: false
    sensor: true

  mapper-ignore: false

  initialize: (options) ->
    super options
    @listen-to this, \contact:start:ENTITY_PLAYER, @drown

  drown: (player) ->
    channels.death.publish cause: \drowning
    player.fall-to-death!

eak.register-actor Water
