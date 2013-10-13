GeneralBody = require "game/physics/GeneralBody"

mediator = require "game/mediator"

module.exports = class DynamicBody extends GeneralBody
  constructor: ->
    super
    @def.bodyType = "dynamic"

  render: (position, angle) =>
    body = @body
    trans = "translate3d(#{(position.x).toFixed 2}px, #{(position.y).toFixed 2}px, 0)"
    r = @angle()
    if r isnt 0 then trans += " rotate(#{angle.toFixed 4}rad)"
    @def.el.style[transform] = trans

  transform = Modernizr.prefixed "transform"
