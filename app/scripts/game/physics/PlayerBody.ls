require! 'game/physics/DynamicBody'

module.exports = class PlayerBody extends DynamicBody
  (start, w, h, el) ->
    def =
      type: \circle
      x: start.x + w/2
      y: start.y + h/2
      radius: 20
      el: el
      id: \ENTITY_PLAYER
      data: restitution: -1
      bd:
        angular-damping: 1

    super def

    @def.body-type = 'player'

    @is-player = true

  roll: (amt, callback) ~> @call \roll [amt] callback
  jump: (callback) ~> @call \jump callback
