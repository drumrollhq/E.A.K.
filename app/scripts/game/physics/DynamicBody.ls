require! { 'game/physics/GeneralBody' 'game/mediator' }

module.exports = class DynamicBody extends GeneralBody
  (def) ->
    super def
    @def.body-type = \dynamic

  render: (position, angle) ~>
    {body} = @
    trans = "translate3d(#{position.x.to-fixed 2}px, #{position.y.to-fixed 2}px, 0)"
    r = @angle!
    if r isnt 0 and not @is-player then trans += " rotate(#{angle.to-fixed 4}rad)"
    @def.el.style[transform] = trans

  transform = Modernizr.prefixed \transform
