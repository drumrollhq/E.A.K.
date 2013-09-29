mediator = require "mediator"

getBodiesFromContact = (c) ->
  [c.GetFixtureA().GetBody().GetUserData(), c.GetFixtureB().GetBody().GetUserData()]

contactEvent = (type) ->
  (contact) ->
    bodies = getBodiesFromContact contact

    send "contactEvent",
      type: type
      a: bodies[0].uid
      b: bodies[1].uid

module.exports = class WorldListener extends Box2D.Dynamics.b2ContactListener
  BeginContact: contactEvent "begin"
  EndContact: contactEvent "end"
