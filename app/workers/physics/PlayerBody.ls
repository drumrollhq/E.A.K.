require! "physics/DynamicBody"

Vector = Box2D.Common.Math.b2Vec2
b2WorldManifold = Box2D.Collision.b2WorldManifold

const jump-limit = Math.PI / 2,
  jump-a = Math.PI / 2 - jump-limit,
  jump-b = Math.PI / 2 + jump-limit,
  max-angular-velocity = 10,
  max-linear-velocity = 4,
  jump-impulse = new Vector(0, -5)

module.exports = class PlayerBody extends DynamicBody
  (def, uid, scale) ->
    super def, uid, scale
    @is-player = yes
    @last-direction = 'left'

  roll: (torque) ~>
    av = @angular-velocity!
    if max-angular-velocity > Math.abs av or torque / av < 0 then @apply-torque torque
    @body.SetAngularDamping 5 - Math.abs torque

    unless @is-on-floor!
      lv = @linear-velocity! .x
      torque = torque / 2
      if max-linear-velocity > Math.abs lv or torque / lv < 0 then @apply-force new Vector torque, 0

    @get-move-data!

  is-on-floor: ~>
    edge = @body.GetContactList!

    while edge?
      manifold = new b2WorldManifold!
      edge.contact.GetWorldManifold manifold
      collision-normal = manifold.m_normal

      fix = edge.contact.GetFixtureB!GetBody!GetUserData!

      if fix.is-player then
        collision-normal.x *= -1
        collision-normal.y *= -1

      angle = Math.atan2 collision-normal.y, collision-normal.x

      if jump-a < angle < jump-b
        return true

      edge = edge.next

    return false

  jump: !~> if @is-on-floor! then @body.ApplyImpulse jump-impulse, @body.GetWorldCenter!

  get-move-data: ~>
    velocity = @linear-velocity!
    position = @position-uncorrected!

    direction =
      | velocity.x > 1 => 'left'
      | velocity.x < -1 => 'right'
      | otherwise => @last-direction

    @last-direction := direction

    classes = [direction]

    if @is-on-floor!
      if 0.7 < Math.abs velocity.x
        classes.push 'running'
      else
        classes.push 'idle'

    else
      if velocity.y > 12
        classes.push 'falling'
      else if 3 > Math.abs velocity.x
        classes.push 'jumping-forward'
      else
        classes.push 'jumping'

    {position, classes}

