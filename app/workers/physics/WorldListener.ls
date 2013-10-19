require! "mediator"

get-bodies-from-contact = (c) ->
  [c.GetFixtureA!GetBody!GetUserData!, c.GetFixtureB!.GetBody!.GetUserData!]

deferred = false

contact-event = (type) ->
  (contact) ->
    bodies = get-bodies-from-contact contact

    evt =
      type: type
      pre: contact.m_oldManifold
      post: contact.m_manifold
      a: bodies[0].uid
      b: bodies[1].uid

    if type is 'begin' then deferred := evt else send 'contactEvent', evt

post-resolve = (contact, impulse) ->
  if deferred isnt false
    deferred <<< {impulse}
    send 'contactEvent', deferred
    deferred := false


module.exports = class WorldListener extends Box2D.Dynamics.b2ContactListener
  BeginContact: contact-event "begin"
  EndContact: contact-event "end"
  PostSolve: post-resolve
