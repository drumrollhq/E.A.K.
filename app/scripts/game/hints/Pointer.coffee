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
    bbox = $target[0].getBoundingClientRect()

    if @hint.side
      offset =
        top: (bbox.top + bbox.bottom) / 2
        left: bbox.right

      @$el.addClass "side"

    else
      offset =
        top: bbox.bottom
        left: (bbox.left + bbox.right) / 2

      if offset.left < 195
        @$inner.css "margin-left", 195 - offset.left

    @$el.appendTo document.body
    @$el.css offset
    @$el.addClass "active"

    if @hint.side
      @$inner.css "margin-top", -(@$inner.height() / 2)

  remove: =>
    @$el.one transitionEnd, =>
      super

    @$el.addClass "done"
