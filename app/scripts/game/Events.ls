require! 'game/mediator'

# Hyperlinks
mediator.on 'beginContact:HYPERLINK&ENTITY_PLAYER' (contact) ->

  impulse = contact.impulse.normal-impulses

  if impulse.0 > 5.5
    window.location.hash = contact.a.def.el.hash

mediator.on 'beginContact:ENTITY_TARGET&ENTITY_PLAYER endContact:ENTITY_TARGET&ENTITY_PLAYER' (contact) ->
  target = contact.a

  $ target.def.el .remove!
  target.destroy!
