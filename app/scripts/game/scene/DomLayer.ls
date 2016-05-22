require! {
  'game/scene/Layer'
}

module.exports = class DomLayer extends Layer
  initialize: (options) ->
    super options
    @$el.css options.{width, height}

  add: (object, {x, y}) ->
    super object, {x, y}
    @$el.append object.el

  set-viewport: (x, y, width, height) ->
    @$el.css prefixed.transform, "translate3d(#{-x}px, #{-y}px, 0)"

    return null
