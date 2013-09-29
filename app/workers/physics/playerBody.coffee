DynamicBody = require "physics/dynamicBody"

Vector = Box2D.Common.Math.b2Vec2
b2WorldManifold = Box2D.Collision.b2WorldManifold

module.exports = class PlayerBody extends DynamicBody
  constructor: ->
    super
    @isPlayer = yes

  jumpLimit = Math.PI / 2
  jumpa = Math.PI / 2 - jumpLimit
  jumpb = Math.PI / 2 + jumpLimit
  maxAngularVelocity = 15
  jumpImpulse = new Vector(0, -7)

  roll: (torque) =>
    av = @angularVelocity()
    if (maxAngularVelocity > Math.abs av) or (torque / av < 0)
      @applyTorque torque

  jump: =>
    console.log "Jump called!"
    edge = @body.GetContactList()

    # Adapted from http://sierakowski.eu/list-of-tips/114-box2d-basics-part-1.html

    while edge isnt null
      manifold = new b2WorldManifold()
      edge.contact.GetWorldManifold manifold
      collisionNormal = manifold.m_normal

      # Check which fixture is the character, and flip normal if needed
      fix = edge.contact.GetFixtureB().GetBody().GetUserData()

      if fix.isPlayer is true
        collisionNormal.x *= -1
        collisionNormal.y *= -1

      angle = Math.atan2 collisionNormal.y, collisionNormal.x

      if jumpa < angle < jumpb
        @body.ApplyImpulse jumpImpulse, @body.GetWorldCenter()
        break

      edge = edge.next

      null
