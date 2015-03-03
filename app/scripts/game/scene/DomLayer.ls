require! {
  'game/scene/Layer'
}

module.exports = class DomLayer extends Layer
  initialize: (options) ->
    super options
    @$el.css options.{width, height}

  add: (el, {x, y}) ->
    super el, {x, y}
    @$el.append el

  set-viewport: (x, y, width, height) ->
    @$el.css prefixed.transform, "translate3d(#{-x}px, #{-y}px, 0)"
