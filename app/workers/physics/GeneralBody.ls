Vector = Box2D.Common.Math.b2Vec2

{b2BodyDef, b2FixtureDef} = Box2D.Dynamics
{b2PolygonShape, b2CircleShape} = Box2D.Collision.Shapes

module.exports = class GeneralBody
  (def, @uid, @scale) ->
    @bd = new b2BodyDef!
    @bd <<< def.{}bd
    @def = def
    if def.width is 0 then def.width = 1
    if def.height is 0 then def.height = 1

  initialize: ->
    {def, bd, scale} = @

    @data = def.{}data
    _.defaults @data, GeneralBody::data-defaults

    bd.position.Set def.x / scale, def.y / scale

    @fds = []

    new-fixture = ~>
      fd = new b2FixtureDef!
      console.log @data.{density, friction, restitution}
      fd <<< @data.{density, friction, restitution}

      if @data.sensor? then fd.is-sensor = true

      @fds[*] = fd

    create-shape = (def, position=false) ~>
      def = _.defaults def, GeneralBody::def-defaults

      switch def.type
        when "circle"
          fd = new-fixture!
          fd.shape = new b2CircleShape def.radius / scale
          def.width = def.height = def.radius

          if position then new Vector def.x / scale, def.y / scale |> fd.shape.SetLocalPosition

        when "rect"
          fd = new-fixture!
          fd.shape = new b2PolygonShape!
          if position
            fd.shape.SetAsOrientedBox def.width / scale / 2, def.height / scale / 2, (new Vector def.x / scale, def.y / scale), 0
          else
            fd.shape.SetAsBox def.width / scale / 2, def.height / scale / 2


        when "compound"
          for shape in def.shapes => create-shape shape, true

    create-shape def

    {@ids} = def

  attach-to: (world) ~>
    body = world.world.CreateBody @bd
    for fd in @fds => body.CreateFixture fd
    body.SetUserData @
    @ <<< {world, body}

  destroy: ~>
    if @world? then @world.world.DestroyBody @body

  halt: ~>
    @body.SetAngularVelocity 0
    @body.SetLinearVelocity new Vector 0, 0

  reset: ~>
    @halt!
    @position x:0, y: 0
    @angle 0

  is-awake: ~> @body.GetType! isnt 0 and @body.IsAwake!

  position: (p) ~>
    if p?
      new Vector (p.x + @def.x) / @scale, (p.y + @def.y) / @scale |> @body.SetPosition
    else
      p = @body.GetPosition!
      return x: (p.x * @scale) - @def.x, y: (p.y * @scale) - @def.y

  position-uncorrected: ~>
    p = @body.GetPosition!
    x: p.x * @scale, y: p.y * @scale

  angle: (a) ~> if a? then @body.SetAngle a else @body.GetAngle!

  angular-velocity: (v) ~>
    if v? then @body.SetAngularVelocity v else @body.GetAngularVelocity!

  linear-velocity: (v) ~>
    if v? then @body.SetLinearVelocity v else @body.GetLinearVelocity!

  apply-torque: (n) ~> @body.ApplyTorque n

  apply-force: (f) ~> @body.ApplyForce f, @body.GetWorldCenter!

  movement: ~> position: @position-uncorrected!, velocity: @linear-velocity!

  def-defaults:
    x: 0
    y: 0
    width: 1
    height: 1
    radius: 0
    type: 'rect'

  data-defaults:
    restitution: 0.3
    friction: 0.7
    density: 1
