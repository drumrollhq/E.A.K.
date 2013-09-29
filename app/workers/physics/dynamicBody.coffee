GeneralBody = require "physics/generalBody"

mediator = require "mediator"

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

module.exports = class DynamicBody extends GeneralBody
  constructor: ->
    super
    @bd.type = b2Body.b2_dynamicBody

    @initialize()

    mediator.on "collectUpdates", @render

    console.log "Created Dynamic Body #{@uid}"

  render: (updates) =>
    body = @body

    if @isAwake()
      updates.push
        uid: @uid
        position: @position()
        angle: @angle()
