Vector = Box2D.Common.Math.b2Vec2
b2AABB = Box2D.Collision.b2AABB
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
b2World = Box2D.Dynamics.b2World
b2MassData = Box2D.Collision.Shapes.b2MassData
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
b2DebugDraw = Box2D.Dynamics.b2DebugDraw
b2MouseJointDef =  Box2D.Dynamics.Joints.b2MouseJointDef;

mediator = require "game/mediator"

module.exports = class World extends Backbone.View
  tagName: "canvas"

  initialize: (@target) ->
    g = new Vector 0, 10

    @world = new b2World g, true

    @listenTo mediator, "resize", => @resize()

    @$el.appendTo document.body

    @resize()

    debug = new b2DebugDraw()
    debug.SetSprite @el.getContext "2d"
    debug.SetDrawScale World::scale
    debug.SetFillAlpha 0.5
    debug.SetLineThickness 1
    debug.SetFlags b2DebugDraw.e_shapeBit + b2DebugDraw.e_pairBit
    @world.SetDebugDraw debug

    @debug = false

    # Get the canvas into the right state:
    @debug = not @debug
    @toggleDebug()

    # Debug interaction:
    mediator.on "keypress:b", => @toggleDebug()

    @last = performance.now()

    # use a 100 point moving average for monitoring the frame rate
    @intervals = (16 for [0..100])
    @skippedlast = false

    mediator.on "frame", @update

  resize: ->
    @$el.css @target.css ["left", "top", "marginTop", "marginLeft", "position"]
    @el.width = @target.width()
    @el.height = @target.height()

  toggleDebug: =>
    if @debug
      @debug = false
      @$el.css display: "none"
    else
      @debug = true
      @$el.css display: "block"

  update: =>
    n = performance.now()
    diff = n - @last

    @intervals.push diff
    @intervals.shift()

    avg = 0
    avg += int for int in @intervals
    avg = avg / @intervals.length

    lim1 = (1000 / 60) + 1
    lim2 = (1000 / 30) + 1

    if avg <= lim1
      diff = lim1
    else #if avg <= 1000 / 30
      # FIXME: proper intervals for slower frame rates
      diff = lim2

      if @skippedlast is false
        @skippedlast = true
        return

    @world.Step diff/1000, 10, 10
    @last = n

    if @debug then @world.DrawDebugData()
    @world.ClearForces()

  scale: 40
