DynamicBody = require "game/physics/DynamicBody"

module.exports = class PlayerBody extends DynamicBody
  constructor: (start, w, h, el) ->
    def =
      type: 'circle'
      x: start.x + w/2
      y: start.y + h/2
      radius: 20
      el: el
      id: "ENTITY_PLAYER"

    super def

    @def.bodyType = "player"

    @isPlayer = yes

  roll: (amt, callback) => @call "roll", [amt], callback
  jump: (amt, callback) => @call "jump", callback
