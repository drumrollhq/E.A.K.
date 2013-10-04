PlayerBody = require "game/physics/playerBody"

mediator = require "game/mediator"

module.exports = class Player extends Backbone.View
  tagName: 'img'
  className: 'player entity'

  initialize: (start = {x:0,y:0}, w, h) ->
    @el.src = "#{mediator.AssetBase}/at.png"
    @el.width = 40
    @el.height = 40

    @$el.attr "data-ignore", true

    @$el.css
      position: "absolute"
      top: h/2 - 20 + start.y
      left: w/2 - 20 + start.x

    @body = new PlayerBody x: start.x, y: start.y, w, h, @el

    @setupKeyboardControls()

    @listenTo mediator, "beginContact:ENTITY_PLAYER&ENTITY_TARGET", ->
      mediator.trigger "kittenfound"

  setupKeyboardControls: ->
    torque = 5

    left = false
    right = false
    up = false
    reqTilt = false
    amount = 0

    b = @body

    @listenTo mediator, "keypress:a,left,d,right,w,up,space", (e) -> e.preventDefault()

    @listenTo mediator, "keydown:a,left", ->
      if not left
        left = true
        right = false

    @listenTo mediator, "keyup:a,left", ->
      if left
        left = false

    @listenTo mediator, "keydown:d,right", ->
      if not right
        right = true
        left = false

    @listenTo mediator, "keyup:d,right", ->
      if right
        right = false

    @listenTo mediator, "keydown:w,up,space", ->
      if not up
        up = true
        b.jump()

    @listenTo mediator, "keyup:w,up,space", ->
      if up
        up = false

    @listenTo mediator, "tilt", (tilt) ->
      reqTilt = true
      amount = tilt

    @listenTo mediator, "uncaughtTap", -> b.jump()

    @listenTo mediator, "frame:process", =>
      if reqTilt
        reqTilt = false
        acc = amount * torque
      else
        acc = if left then -torque else if right then torque else 0

      b.roll acc

      b.absolutePosition (p) ->
        mediator.trigger "playermove", p
