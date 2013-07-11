World = require "game/physics/world"

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

module.exports = class GeneralBody
  constructor: (def) ->
    @bd = new b2BodyDef()
    @def = def

  initialize: ->
    bd = @bd
    s = @def

    bd.position.Set s.x / World::scale, s.y / World::scale

    fd = new b2FixtureDef()
    fd.density = 1
    fd.friction = 0.55
    fd.restitution = 0.4

    @fd = fd

    if s.type is "circle"
      fd.shape = new b2CircleShape s.radius / World::scale
      s.width = s.height = s.radius
    else
      fd.shape = new b2PolygonShape()
      fd.shape.SetAsBox s.width / World::scale, s.height / World::scale

  attachTo: (world) =>
    body = world.world.CreateBody @bd
    body.CreateFixture @fd
    body.SetUserData @
    @body = body
    @world = world
