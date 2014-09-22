require! {
  'ui/focus'
}

transition-end = {
  'WebkitAnimation': 'webkitAnimationEnd'
  'MozAnimation': 'animationend'
  'OAnimation': 'oanimationend'
  'msAnimation': 'MSAnimationEnd'
  'animation': 'animationend'
}[Modernizr.prefixed 'animation']

module.exports =  class PointerHint extends Backbone.View
  tag-name: \div
  class-name: \pointer-hint

  events:
    'click .dismiss': 'dismiss'

  initialize: (hint) ->
    @$inner = $ '<div></div>'
      ..append-to @$el
      ..html hint.content
    @hint = hint

  render: ~>
    $target = $ @hint.target
    bbox = $target.0.get-bounding-client-rect!
    bbox <<< {
      center-x: (bbox.left + bbox.right) / 2
      center-y: (bbox.top + bbox.bottom) / 2
    }

    offset = switch @hint.position
    | \below => top: bbox.bottom, left: bbox.center-x
    | \right => top: bbox.center-y, left: bbox.right
    | \above => top: bbox.top, left: bbox.center-x
    | \left => top: bbox.center-y, left: bbox.left

    if @hint.position in <[above below]> and offset.left < 195px
      @$inner.css \margin-left 195px - offset.left

    @$el
      ..append-to document.body
      ..css offset
      ..add-class \active
      ..add-class @hint.class
      ..add-class "position-#{@hint.position}"

    if @hint.position in <[left right]> then @$inner.css \margin-top, -(@$el.height! / 2)
    if @hint.position is \above then @$el.css \top offset.top - @$el.outer-height!
    if @hint.position is \left then @$el.css \left offset.left - @$el.outer-width!

    if @hint.focus then focus.focus $target.0

  remove: ~>
    if @hint.focus then focus.blur!
    @$el
      ..one transition-end, ~>
        super!
      ..add-class \done

  dismiss: (e) ~>
    e.prevent-default!
    @remove!
