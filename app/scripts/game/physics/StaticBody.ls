require! 'game/physics/GeneralBody'

module.exports = class StaticBody extends GeneralBody
  (def) ->
    super def
    @def.bodyType = \static
