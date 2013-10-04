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
  constructor: (def, @uid, @scale) ->
    @bd = new b2BodyDef()
    @def = def
    if def.width is 0 then def.width = 1
    if def.height is 0 then def.height = 1

  initialize: ->
    def = @def
    bd = @bd

    @data = if def.data isnt undefined then def.data else {}

    bd.position.Set def.x / @scale, def.y / @scale

    @fds = []

    newFixture = =>
      fd = new b2FixtureDef()
      fd.density = @data.density or 1
      fd.friction = @data.friction or 0.7
      fd.restitution = @data.restitution or 0.3

      if @data.sensor is true
        fd.isSensor = true

      @fds.push fd

      fd

    createShape = (def, position=false) =>
      def = _.defaults def, GeneralBody::defDefaults
      if def.type is "circle"
        fd = newFixture()
        fd.shape = new b2CircleShape def.radius / @scale
        def.width = def.height = def.radius

        if position
          fd.shape.SetLocalPosition new Vector def.x / @scale, def.y / @scale
      else if def.type is "rect"
        fd = newFixture()
        fd.shape = new b2PolygonShape()
        if position
          fd.shape.SetAsOrientedBox def.width / @scale / 2, def.height / @scale / 2, (new Vector def.x / @scale, def.y / @scale), 0
        else
          fd.shape.SetAsBox def.width / @scale / 2, def.height / @scale / 2
      else if def.type is "compound"
        createShape shape, true for shape in def.shapes

    createShape def

    @ids = def.ids

  attachTo: (world) =>
    body = world.world.CreateBody @bd
    body.CreateFixture fd for fd in @fds
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
    @position x: 0, y: 0
    @body.SetAngle 0

  isAwake: =>
    @body.GetType() isnt 0 and @body.IsAwake()

  position: (p) =>
    if p is undefined
      p = @body.GetPosition()
      return x: (p.x * @scale) - @def.x, y: (p.y * @scale) - @def.y
    else
      @body.SetPosition new Vector (p.x + @def.x) / @scale, (p.y + @def.y) / @scale

  positionUncorrected: ->
    p = @body.GetPosition()
    x: p.x * @scale, y: p.y * @scale

  absolutePosition: ->
    p = @body.GetPosition()
    x: p.x * @scale, y: p.y * @scale

  angle: -> @body.GetAngle()

  angularVelocity: -> @body.GetAngularVelocity()

  applyTorque: (n) -> @body.ApplyTorque n

  defDefaults:
    x: 0
    y: 0
    width: 1
    height: 1
    radius: 0
    type: 'rect'
