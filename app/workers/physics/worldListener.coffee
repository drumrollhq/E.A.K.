mediator = require "mediator"

getBodiesFromContact = (c) ->
  [c.GetFixtureA().GetBody().GetUserData(), c.GetFixtureB().GetBody().GetUserData()]

contactEvent = (type) ->
  (contact) ->
    bodies = getBodiesFromContact contact

    for idA in bodies[0].ids
      for idB in bodies[1].ids
        mediator.trigger "#{type}Contact:#{idA}&#{idB}",
          contact: contact
          a: bodies[0]
          b: bodies[1]
        mediator.trigger "#{type}Contact:#{idB}&#{idA}",
          contact: contact
          a: bodies[1]
          b: bodies[0]

module.exports = class WorldListener extends Box2D.Dynamics.b2ContactListener
  BeginContact: contactEvent "begin"
  EndContact: contactEvent "end"
