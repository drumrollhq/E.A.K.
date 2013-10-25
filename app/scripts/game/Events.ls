require! 'game/mediator'

animation-end = {
  "WebkitAnimation": "webkitAnimationEnd"
  "MozAnimation": "mozanimationend"
  "OAnimation": "oanimationend"
  "msAnimation": "MSAnimationEnd"
  "animation": "animationend"}[Modernizr.prefixed "animation"]

# Hyperlinks
mediator.on 'beginContact:HYPERLINK&ENTITY_PLAYER' (contact) ->

  impulse = contact.impulse.normal-impulses

  if 5.5 < impulse.0 < 8.5
    window.location.hash = contact.a.def.el.hash

mediator.on 'beginContact:ENTITY_TARGET&ENTITY_PLAYER endContact:ENTITY_TARGET&ENTITY_PLAYER' (contact) ->
  target = contact.a

  target.destroy!

  unless target.destroyed
    mediator.trigger 'kittenfound'

  target.destroyed = true

  $el = $ target.def.el

  $el.one animation-end, -> $el.remove!

  $el.add-class 'found'

