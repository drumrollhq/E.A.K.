module.exports = class Actor extends Backbone.View
  initialize: (start = {x: 0, y: 0}) ->
    @subs = []
    @start = start
    @origin = start.{x, y}
    width = @$el.width!
    height = @$el.height!

    if @physics-ignore then @$el.attr \data-ignore true
    @$el.css {
      position: \absolute
      left: start.x - width / 2
      top: start.y - height / 2
    }

    # Data for physics
    this <<< {
      type: \rect
      x: start.x
      y: start.y
      width: width
      height: height
      rotation: 0
      data:
        id: "ENTITY_#{@actor-type!to-upper-case!}"
    } <<< (@physics or {})

    @{}data.actor = true

  actor-type: -> Object.get-prototype-of this .constructor.display-name.to-lower-case!

  reset: (origin = @origin) ~>
    @ <<< {
      x: origin.x
      y: origin.y
      rotation: 0
      prepared: false
    }

    @$el.css {
      left: origin.x - @width/2
      top: origin.y - @height/2
    }

    @prepare!

  remove: ~>
    super!
    for sub in @subs => sub.unsubscribe!

  draw: ->
    @$el.css prefixed.transform, "translate3d(#{@p.x - @x}px, #{@p.y - @y}px, 0)"
