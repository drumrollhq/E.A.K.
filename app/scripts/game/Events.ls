require! {
  'channels'
  'logger'
}

actions = {
  kill: (player) ->
    player.fall-to-death!

  spike: (player) -> actions.kill player
}

# Hyperlinks
channels.parse 'contact: start: HYPERLINK + ENTITY_PLAYER' .subscribe (contact) ->
  [player, link] = contact.find 'ENTITY_PLAYER'

  if player.deactivated then return
  speed = player.last-v.y
  if 3.5px < speed < 10px then window.location.href = link.el.href

# Portals
portal = null
player = null
channels.parse 'contact: start: PORTAL + ENTITY_PLAYER' .subscribe (contact) ->
  [player, portal] := contact.find 'ENTITY_PLAYER'

channels.parse 'contact: end: PORTAL + ENTITY_PLAYER' .subscribe ->
  portal := null

channels.parse 'key-down: down, s' .subscribe ->
  unless portal then return

  if player.deactivated then return
  if player.last-fall-dist > 200px then return

  player
    ..frozen = true
    ..handle-input = false
    ..classes-disabled = true

  player.el.class-list.add 'portal-out'
  portal.el.class-list.add 'portal-out'

  logger.log 'portal', player: player.{p, v}

  <- set-timeout _, 750
  window.location.href = portal.el.href

# Falling to death, actions:
channels.parse 'contact: start: ENTITY_PLAYER' .subscribe (contact) ->
  [player, other] = contact.find 'ENTITY_PLAYER'
  if player.deactivated then return

  # First, check for and trigger actions
  if other.data?.action?
    action = other.data.action
    if actions[action]?
      logger.log 'action', {action}
      actions[action] player, other

  if player.last-fall-dist > 300px and not other.data?.sensor?
    channels.death.publish cause: 'fall-to-death'

# Kitten finding
channels.parse 'contact: start: ENTITY_PLAYER + ENTITY_TARGET' .subscribe (contact) ->
  [player, kitten] = contact.find 'ENTITY_PLAYER'
  if player.deactivated then return

  kitten.destroy!

  unless kitten.destroyed
    logger.log 'kitten', player: player.{v, p}
    channels.kitten.publish {}

  kitten.destroyed = true

  $el = $ kitten.el
  blink = $el.find '.box-blink'
  blink.css 'display' 'none'
  blink-controller = blink.data 'sprite-controller'

  burst = $el.find '.box-burst'
  burst.css 'display' 'block'
  burst-controller = burst.data 'sprite-controller'

  burst-controller.restart!
  $el.find '.kitten-anim' .one prefixed.animation-end, ->
    burst-controller.remove!
    blink-controller.remove!
    $el.remove!

  $el.add-class 'found'
