GeneralBody = require "game/physics/generalBody"

module.exports = class StaticBody extends GeneralBody
  constructor: ->
    super
    @def.bodyType = "static"
