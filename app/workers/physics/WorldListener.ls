require! "mediator"

get-bodies-from-contact = (c) ->
  [c.GetFixtureA!GetBody!GetUserData!, c.GetFixtureB!.GetBody!.GetUserData!]

contact-event = (type) ->
  (contact) ->
    bodies = get-bodies-from-contact contact

    send "contactEvent",
      type: type
      a: bodies[0].uid
      b: bodies[1].uid

module.exports = class WorldListener extends Box2D.Dynamics.b2ContactListener
  BeginContact: contact-event "begin"
  EndContact: contact-event "end"
