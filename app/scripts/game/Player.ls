require! {
  'game/physics/PlayerBody'
  'game/mediator'
}

{reduce} = _

module.exports = class Player extends Backbone.View
  tag-name: \div
  class-name: 'player entity'

  initialize: (start = {x: 0, y: 0}, w, h) ->
    @el.width = @el.height = 40

    @$inner-el = $ '<div></div>'
      ..add-class 'player-inner'
      ..append-to @$el

    @$el.attr \data-ignore true

    @$el.css do
      position: \absolute
      top: h/2 - 20 + start.y
      left: w/2 - 20 + start.x

    @body = new PlayerBody start.{x, y}, w, h, @el

    @last-classes = []
    @classes-disabled = false

    @setup-keyboard-controls!

  apply-classes: (classes) ~>
    for classname in @last-classes
      if classname not in classes then @$el.remove-class "player-#classname"

    for classname in classes
      if classname not in @last-classes then @$el.add-class "player-#classname"

    @last-classes := classes

  setup-keyboard-controls: ->
    const torque = 5

    left = false
    right = false
    up = false
    req-tilt = false
    amount = 0

    b = @body

    @listen-to mediator, 'keypress:a,left,d,right,w,up,space' (e) -> e.prevent-default!

    @listen-to mediator, 'keydown:a,left' -> unless left
      left := true
      right := false

    @listen-to mediator, 'keyup:a,left' -> if left
      left := false

    @listen-to mediator, 'keydown:d,right' -> unless right
      right := true
      left := false

    @listen-to mediator, 'keyup:d,right' -> if right
      right := false

    @listen-to mediator, 'keydown:w,up,space' -> unless up
      up := true
      b.jump!

    @listen-to mediator, 'keyup:w,up,space' -> if up
      up := false

    @listen-to mediator, \tilt, (tilt) ->
      req-tilt := true
      amount := true

    @listen-to mediator, \uncaughtTap -> b.jump!

    last-classes = []
    classes-disabled = false

    @listen-to mediator, \frame:process ~>
      if req-tilt
        req-tilt := false
        acc = amount * torque
      else
        acc = if left then -torque else if right then torque else 0

      movedata <~ b.roll acc

      {position, classes} = movedata

      mediator.trigger \playermove, position

      unless @classes-disabled => @apply-classes classes

    @listen-to mediator, 'beginContact:ENTITY_PLAYER&*' (contact) ~>
      impulse = contact.impulse.normal-impulses |> reduce _, (a, b) -> a + b

      if impulse > 8.5 then
        @classes-disabled = true
        @apply-classes ['pain']
        <~ set-timeout _, 500
        @classes-disabled = false

