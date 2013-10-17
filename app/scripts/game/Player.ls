require! {
  'game/physics/PlayerBody'
  'game/mediator'
}

module.exports = class Player extends Backbone.View
  tag-name: \img
  class-name: 'player entity'

  initialize: (start = {x: 0, y: 0}, w, h) ->
    @el.src = "/content/at.png"
    @el.width = @el.height = 40

    @$el.attr \data-ignore true

    @$el.css do
      position: \absolute
      top: h/2 - 20 + start.y
      left: w/2 - 20 + start.x

    @body = new PlayerBody start.{x, y}, w, h, @el

    @setup-keyboard-controls!

    @listen-to mediator, 'beginContact:ENTITY_PLAYER&ENTITY_TARGET', ->
      mediator.trigger \kittenfound

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

    @listen-to mediator, \frame:process ~>
      if req-tilt
        req-tilt := false
        acc = amount * torque
      else
        acc = if left then -torque else if right then torque else 0

      b.roll acc

      p <- b.absolute-position

      mediator.trigger \playermove, p
