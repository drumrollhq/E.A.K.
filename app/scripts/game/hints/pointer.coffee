transitionEnd = {
  "WebkitAnimation": "webkitAnimationEnd"
  "MozAnimation": "animationend"
  "OAnimation": "oanimationend"
  "msAnimation": "MSAnimationEnd"
  "animation": "animationend"}[Modernizr.prefixed "animation"]

module.exports = class PointerHint extends Backbone.View
  tagName: "div"
  className: "pointer-hint"

  initialize: (hint) ->
    @$inner = $ "<div></div>"
    @$inner.appendTo @$el
    @$inner.html hint.content
    @hint = hint

  render: =>
    $target = $ @hint.target
    offset = $target.offset()
    width = $target.width()
    height = $target.height()

    offset.top += height
    offset.left += width / 2

    @$el.appendTo document.body
    @$el.css offset
    @$el.addClass "active"

  remove: =>
    @$el.one transitionEnd, =>
      super

    @$el.addClass "done"
