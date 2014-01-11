require! 'game/mediator'

# Hyperlinks
mediator.on 'begin-contact:HYPERLINK:ENTITY_PLAYER' (contact) ->

  speed = contact.b.last-v.y
  if 3.5px < speed < 10px then window.location.href = contact.a.el.href

# Falling to death:
mediator.on 'begin-contact:ENTITY_PLAYER:*' (contact) ->
  console.log contact.a.last-fall-frames
  if contact.a.last-fall-frames > 55 and not contact.b.data?.sensor?
    console.log contact.a.last-fall-frames
    mediator.trigger 'fall-to-death'

# Kitten finding
mediator.on 'begin-contact:ENTITY_TARGET:ENTITY_PLAYER' (contact) ->
  target = contact.a

  target.destroy!

  unless target.destroyed
    mediator.trigger 'kittenfound'

  target.destroyed = true

  $el = $ target.el

  $el.one prefixed.animation-end, -> $el.remove!

  $el.add-class 'found'

