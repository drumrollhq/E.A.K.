GeneralBody = require "game/physics/GeneralBody"

module.exports = class StaticBody extends GeneralBody
  constructor: ->
    super
    @def.bodyType = "static"
