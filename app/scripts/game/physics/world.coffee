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

WorldListener = require "game/physics/worldListener"

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
    @listenTo mediator, "keypress:b", => @toggleDebug()

    # Make sure that events are triggered for collisions etc.
    @world.SetContactListener new WorldListener

    @listenTo mediator, "frame:process", @update

  resize: =>
    @$el.css @target.offset()
    @$el.css "position", "absolute"
    @el.width = @target.width()
    @el.height = @target.height()

  stop: =>
    @stopListening mediator, "frame:process", @update

  toggleDebug: =>
    if @debug
      @debug = false
      @$el.css display: "none"
    else
      @debug = true
      @$el.css display: "block"

  update: (t) =>
    @world.Step t/1000, 10, 10

    if @debug then @world.DrawDebugData()
    @world.ClearForces()

  remove: =>
    @world.SetDestructionListener()
    super

  scale: 40
