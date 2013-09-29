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
b2MouseJointDef =  Box2D.Dynamics.Joints.b2MouseJointDef

mediator = require "mediator"

WorldListener = require "physics/worldListener"

StaticBody = require "physics/staticBody"
DynamicBody = require "physics/dynamicBody"

working = no

class World
  constructor: ->
    g = new Vector 0, 10

    @world = new b2World g, true

    @entities = []

    ### Debug disabled ## #
    debug = new b2DebugDraw()
    debug.SetSprite !?!?!
    debug.SetDrawScale World::scale
    debug.SetFillAlpha 0.5
    debug.SetLineThickness 1
    debug.SetFlags b2DebugDraw.e_shapeBit + b2DebugDraw.e_pairBit
    @world.SetDebugDraw debug
    ###

    @world.SetContactListener new WorldListener

    mediator.on "triggerUpdate", @update

    mediator.on "create:body", @createBody

    mediator.on "entityCall", @entityCall

  update: (t) =>
    unless working
      working = yes
      @world.Step t/1000, 10, 10
      working = no

  createBody: (data) =>
    uid = data.uid
    def = data.def

    body = if def.bodyType is "static" then new StaticBody def, uid, World::scale else new DynamicBody def, uid, World::scale
    body.attachTo @

    @entities[uid] = body

  entityCall: (data, done) =>
    entity = @entities[data.uid]
    done entity[data.name].apply entity, data.arguments

  scale: 40

new World()
