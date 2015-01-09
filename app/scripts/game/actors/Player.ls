require! {
  'game/actors/Actor'
  'lib/channels'
  'lib/keys'
  'logger'
}

const max-move-speed = 4px,
  move-acc = 0.3px,
  move-acc-in-air = 0.2px
  move-damp = 0.7px,
  move-damp-in-air = 0.01px
  jump-speed = 5.4px,
  max-jump-frames = 10,

player-html = '''
  <div class="player-inner">
    <div class="player-head">
      <div class="player-ear-left"></div>
      <div class="player-ear-right"></div>
      <div class="player-face"></div>
      <div class="player-eyes"></div>
    </div>
    <div class="player-body"></div>
    <div class="player-leg-left"></div>
    <div class="player-leg-right"></div>
  </div>
'''

{reduce} = _

module.exports = class Player extends Actor
  tag-name: \div
  class-name: 'player entity'
  physics-ignore: true

  initialize: (start = {x: 0, y: 0, colour: 'white'}) ->
    @el.width = 33px
    @el.height = 54px

    @$el.add-class "player-colour-#{start.colour}"
    @$el.html player-html
    @$inner-el = @$el.find '.player-inner'

    @physics = {
      width: @el.width
      height: @el.height
      data:
        player: true
        id: 'ENTITY_PLAYER'
        dynamic: true
        use-gravity: true
    }

    super start

    @$el.attr \data-ignore true
    @$el.css {
      left: start.x - @el.width/2
      top: start.y - @el.height/2
    }

    @last-classes = []
    @last-direction = 'right'
    @classes-disabled = false

    @subs[*] = channels.death.filter ( .cause is 'fall-out-of-world' ) .subscribe ~> @reset!
    @subs[*] = channels.death.filter ( .cause is 'fall-to-death' ) .subscribe @fall-to-death
    @subs[*] = channels.post-frame.subscribe @calc-classes
    @subs[*] = channels.death.subscribe (death) ~>
      logger.log 'death', {cause: death.cause, data: death.data, player: @{p, v}}

  calc-classes: ~>
    unless @classes-disabled
      classes = []

      classes[*] = @last-direction =
        | @v.x > 0.7 => 'left'
        | @v.x < -0.7 => 'right'
        | otherwise => @last-direction

      classes[*] =
        | @state is 'on-thing' and 0.7 < abs @v.x => 'running'
        | @state is 'on-thing' and (keys.right or keys.left) => 'running'
        | @state is 'on-thing' => 'idle'
        | @fall-dist > 150 => 'falling'
        | 3 > abs @v.x => 'jumping-forward'
        | otherwise => 'jumping'

      if @state is 'on-thing' => classes[*] = 'on-thing'

      @apply-classes classes

  apply-classes: (classes) ~>
    for classname in @last-classes
      if classname not in classes then @$el.remove-class "player-#classname"

    for classname in classes
      if classname not in @last-classes then @$el.add-class "player-#classname"

    @last-classes := classes

  draw: ->
    @apply-classes []
    super!
    channels.player-position.publish @p.{x, y}

  fall-to-death: ~>
    @apply-classes ['squish' @last-direction]
    @deactivated = true
    @classes-disabled = true
    <~ set-timeout _, 1500
    @classes-disabled = false
    @deactivated = false
    @reset!

  # Handle input:
  step: (dt) ->
    # Moving right:
    if keys.right && !@deactivated
      # If the object is on a thing, move with standard acceleration. If not, move with in-air acceleration
      @v.x += if @state is 'on-thing'
        if @v.x > 0
          move-acc * dt
        else
          move-damp * dt
      else
        move-acc-in-air * dt

      # Constrain speed
      if @v.x >= max-move-speed
        @v.x = max-move-speed

    # Moving left. Same as moving right, but the other way
    else if keys.left && !@deactivated
      @v.x -= if @state is 'on-thing'
        if @v.x < 0
          move-acc * dt
        else
          move-damp * dt
      else
        move-acc-in-air * dt

      if @v.x <= - max-move-speed
        @v.x = - max-move-speed

    # Not moving.
    else
      # If the object is moving right:
      if @v.x > 0
        # Slow it down. The rate depends on if it's on the ground or not
        @v.x -= if @state is 'on-thing' then move-damp else move-damp-in-air

        # If it slows down so much it starts going the other way, stop it
        if @v.x < 0 then @v.x = 0

      # Repeat for moving left:
      else if @v.x < 0
        @v.x += if @state is 'on-thing' then move-damp else move-damp-in-air
        if @v.x > 0 then @v.x = 0

    # Jumping:
    # jump-frames is a timer that counts a the number of frames the player can be
    # accelerating for.
    # jump-state indicates the state of the jump
    #
    # If the jump key is pressed and (the player is on the ground or mid-jump):
    {jump-state, state, jump-frames} = this
    jump-key = if @deactivated then false else keys.jump
    if jump-key and jump-state is \ready and state is \on-thing
      @fixed-to = null
      @v.y = -jump-speed
      @jump-frames = max-jump-frames
      @jump-state = \jumping
      @fall-dist = 0

    else if jump-key and jump-state is \jumping and state in <[jumping contact]> and jump-frames > 0
      @v.y = -jump-speed
      @jump-frames -= dt
      @jump-state = \jumping
      @fall-dist = 0

    else if jump-key and jump-frames <= 0
      @jump-state = \stop

    else
      @jump-state = \ready
