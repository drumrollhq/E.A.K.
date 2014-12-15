require! {
  'channels'
  'logger'
}

actions = {
  # ALLOC
  kill: (player) -> channels.death.publish cause: 'fall-to-death'
  spike: (player) -> actions.kill player
}

fall-limit = 200px

# Hyperlinks
channels.parse 'contact: start: HYPERLINK + ENTITY_PLAYER' .subscribe (contact) ->
  # ALLOC
  [player, link] = contact.find 'ENTITY_PLAYER'

  if player.deactivated then return
  speed = player.last-v.y
  if 3.5px < speed < 10px then window.location.href = link.el.href

# Portals
portal = null
player = null
channels.parse 'contact: start: PORTAL + ENTITY_PLAYER' .subscribe (contact) ->
  # ALLOC
  [player, portal] := contact.find 'ENTITY_PLAYER'

channels.parse 'contact: end: PORTAL + ENTITY_PLAYER' .subscribe ->
  portal := null

channels.parse 'key-down: down, s, j' .subscribe ->
  unless portal then return
  portal-el = portal.el
  portal := null

  if player.deactivated then return
  if player.last-fall-dist > fall-limit then return

  player
    ..frozen = true
    ..handle-input = false
    ..classes-disabled = true

  # ALLOC
  player.el.class-list.add 'portal-out'
  portal-el.class-list.add 'portal-out'

  # ALLOC
  channels.game-commands.publish command: 'portal'
  # ALLOC
  logger.log 'action', type: 'portal', player: player.{p, v}

  <- set-timeout _, 750
  window.location.href = portal-el.href

# Falling to death, actions:
channels.parse 'contact: start: ENTITY_PLAYER' .subscribe (contact) ->
  # ALLOC
  [player, other] = contact.find 'ENTITY_PLAYER'
  if player.deactivated then return

  # First, check for and trigger actions
  if other.data?.action?
    action = other.data.action
    if actions[action]?
      # ALLOC
      logger.log 'action', {type: action}
      actions[action] player, other

  if player.last-fall-dist > 300px and not other.data?.sensor?
    # ALLOC
    channels.death.publish cause: 'fall-to-death'

# Exits:
channels.parse 'contact: start: ENTITY_PLAYER + ENTITY_EXIT' .subscribe (contact) ->
  # ALLOC
  [player, exit] = contact.find 'ENTITY_PLAYER'
  if player.deactivated or player.last-fall-dist > fall-limit then return
  href = exit.data.href or exit.el.href
  if href? then window.location.href = href

# Kitten finding
channels.parse 'contact: start: ENTITY_PLAYER + ENTITY_TARGET' .subscribe (contact) ->
  # ALLOC
  [player, kitten] = contact.find 'ENTITY_PLAYER'
  if player.deactivated or player.last-fall-dist > fall-limit then return

  kitten.destroy!

  if kitten.destroyed then return

  # ALLOC
  logger.log 'kitten', player: player.{v, p}
  # ALLOC
  channels.kitten.publish {}

  kitten.destroyed = true

  $el = $ kitten.el
  # ALLOC
  blink = $el.find '.box-blink'
  blink.css 'display' 'none'
  blink-controller = blink.data 'sprite-controller'

  burst = $el.find '.box-burst'
  burst.css 'display' 'block'
  burst-controller = burst.data 'sprite-controller'

  burst-controller.restart!
  # ALLOC
  $el.find '.kitten-anim' .one prefixed.animation-end, ->
    burst-controller.remove!
    blink-controller.remove!
    $el.remove!

  $el.add-class 'found'
