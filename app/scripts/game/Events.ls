require! 'game/mediator'

# Hyperlinks
mediator.on 'begin-contact:HYPERLINK:ENTITY_PLAYER' (contact) ->

  speed = contact.b.last-v.y
  if 3.5px < speed < 10px then window.location.href = contact.a.el.href

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

