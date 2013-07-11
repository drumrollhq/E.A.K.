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
    debug.SetFlags b2DebugDraw.e_shapeBit
    @world.SetDebugDraw debug
    @debug = true

    # Debug interaction:
    mediator.on "keypress:b", => @toggleDebug()

    @last = performance.now()

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
    diff = (n - @last) / 1000

    if diff > 0.5 then diff = 0.5

    @world.Step diff, 10, 10
    @last = n

    if @debug then @world.DrawDebugData()
    @world.ClearForces()

  scale: 50
