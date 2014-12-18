require! 'ui/focus'

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
    scope = if @hint.scope then $ @hint.scope else $ document.body
    $target = scope.find @hint.target

    parent = scope.0.get-bounding-client-rect!
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

    console.log {parent, bbox}

    offset.top -= parent.top
    offset.left -= parent.left

    if @hint.position in <[above below]> and offset.left < 195px
      @$inner.css \margin-left 195px - offset.left

    @$el
      ..append-to scope
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
      ..one prefixed.animation-end, ~>
        super!
      ..add-class \done

  dismiss: (e) ~>
    e.prevent-default!
    @remove!
