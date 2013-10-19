require! 'game/mediator'

contact <- mediator.on 'beginContact:HYPERLINK&ENTITY_PLAYER'

impulse = contact.impulse.normal-impulses

if impulse.0 > 5.5
  window.location.hash = contact.a.def.el.hash
