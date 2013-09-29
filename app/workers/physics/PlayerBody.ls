require! "physics/DynamicBody"

Vector = Box2D.Common.Math.b2Vec2
b2WorldManifold = Box2D.Collision.b2WorldManifold

const jump-limit = Math.PI / 2,
  jump-a = Math.PI / 2 - jump-limit,
  jump-b = Math.PI / 2 + jump-limit,
  max-angular-velocity = 15,
  jump-impulse = new Vector(0, -7)

module.exports = class PlayerBody extends DynamicBody
  (def, uid, scale) ->
    super def, uid, scale
    @is-player = yes

  roll: (torque) ~>
    av = @angular-velocity!
    if max-angular-velocity > Math.abs av or torque / av < 0 then @apply-torque torque

  jump: !~>
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
        @body.ApplyImpulse jump-impulse, @body.GetWorldCenter!
        break

      edge = edge.next
