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

scale = World::scale

module.exports = class GeneralBody extends Backbone.Model
  constructor: (def) ->
    @bd = new b2BodyDef()
    @def = def
    @data = if def.data isnt undefined then def.data else {}

  initialize: ->
    bd = @bd
    s = @def

    bd.position.Set s.x / scale, s.y / scale

    fd = new b2FixtureDef()
    fd.density = 1
    fd.friction = 0.7
    fd.restitution = 0.3

    if @data.sensor is true
      fd.isSensor = true

    @fd = fd

    if s.type is "circle"
      fd.shape = new b2CircleShape s.radius / scale
      s.width = s.height = s.radius
    else
      fd.shape = new b2PolygonShape()
      fd.shape.SetAsBox s.width / scale / 2, s.height / scale / 2

    ids = ["*"]
    if s.id isnt undefined
      ids.push s.id

    if s.el isnt undefined
      el = s.el
      ids.push "#" + el.id if el.id isnt ""
      ids.push "." + className for className in el.classList

    ids.push @data.id if @data.id isnt undefined

    @ids = ids

  attachTo: (world) =>
    body = world.world.CreateBody @bd
    body.CreateFixture @fd
    body.SetUserData @
    @body = body
    @world = world

  destroy: =>
    if @world isnt undefined then @world.world.DestroyBody @body

  halt: =>
    b = @body
    b.SetAngularVelocity 0
    b.SetLinearVelocity new Vector 0, 0

  reset: =>
    @halt()
    @position x:0, y: 0
    @body.SetAngle 0

  isAwake: -> @body.GetType() isnt 0 and @body.IsAwake()

  position: (p) ->
    if p is undefined
      p = @body.GetPosition()
      return x: (p.x * scale) - @def.x, y: (p.y * scale) - @def.y
    else
      @body.SetPosition new Vector (p.x + @def.x) / scale, (p.y + @def.y) / scale

  positionUncorrected: ->
    p = @body.GetPosition()
    x: (p.x * scale), y: (p.y * scale)

  absolutePosition: ->
    p = @body.GetPosition()
    x: p.x * scale, y: p.y * scale

  angle: -> @body.GetAngle()

  angularVelocity: -> @body.GetAngularVelocity()
