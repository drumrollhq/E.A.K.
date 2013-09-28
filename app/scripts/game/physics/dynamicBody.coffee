GeneralBody = require "game/physics/generalBody"

mediator = require "game/mediator"

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
    @def.bodyType = "dynamic"

    @initialize()

    @listenTo mediator, "frame:render", @render

  render: =>
    body = @body
    if @isAwake()
      p = @position()
      trans = "translate3d(#{(p.x).toFixed 2}px, #{(p.y).toFixed 2}px, 0)"
      r = @angle()
      if r isnt 0 then trans += " rotate(#{r.toFixed 4}rad)"
      @def.el.style[transform] = trans

  transform = Modernizr.prefixed "transform"