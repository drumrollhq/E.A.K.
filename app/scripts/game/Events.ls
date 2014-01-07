require! 'game/mediator'

# Hyperlinks
mediator.on 'beginContact:HYPERLINK&ENTITY_PLAYER' (contact) ->

  impulse = contact.impulse.normal-impulses

  if 5.5 < impulse.0 < 8.5
    window.location.hash = contact.a.def.el.hash

mediator.on 'begin-contact:ENTITY_TARGET:ENTITY_PLAYER' (contact) ->
  target = contact.a

  console.log 'CONTACT!!!!'

  target.destroy!

  unless target.destroyed
    mediator.trigger 'kittenfound'

  target.destroyed = true

  $el = $ target.el

  $el.one prefixed.animation-end, -> $el.remove!

  $el.add-class 'found'

