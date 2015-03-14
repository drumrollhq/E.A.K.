require! {
  'game/actors/Actor'
  'lib/channels'
  'lib/keys'
  'logger'
}

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

  @MAX_MOVE_SPEED = 4px
  @MOVE_ACC = 0.3px
  @MOVE_ACC_IN_AIR = 0.2px
  @FRICTION = 0.7px
  @FRICTION_IN_AIR = 0.01px
  @JUMP_SPEED = 5.4px
  @MAX_JUMP_FRAMES = 10
  @FALL_TO_DEATH_LIMIT = 300px

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
    @subs[*] = channels.death.subscribe (death) ~>
      logger.log 'death', {cause: death.cause, data: death.data, player: @{p, v}}

    # @listen-to this, 'all', console.log.bind console
    @listen-to this, \contact:start, @contact-start
    @listen-to this, \contact:end, @contact-end
    @listen-to this, \set:origin, @origin-updated

  after-physics: ->
    @calc-classes!

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
    super!
    channels.player-position.publish @p.{x, y}

  contact-start: (other) ->
    if other.el then other.el.class-list.add \PLAYER_CONTACT
    if @deactivated then return

    # Check for falling to death:
    if @last-fall-dist > Player.FALL_TO_DEATH_LIMIT and not other.data?.sensor?
      channels.death.publish cause: 'fall-to-death'

  contact-end: (other) ->
    if other.el then other.el.class-list.remove \PLAYER_CONTACT

  fall-to-death: ~>
    @apply-classes ['squish' @last-direction]
    @deactivated = true
    @classes-disabled = true
    <~ set-timeout _, 1500
    @classes-disabled = false
    @deactivated = false
    @reset!

  # Save player position when origin updated:
  origin-updated: (current, prev) ->
    unless current === @store.get \stage.state.playerPos
      @store.patch-stage-state \playerPos, current

  # Handle input:
  step: (dt) ->
    # Moving right:
    if keys.right && !@deactivated
      # If the object is on a thing, move with standard acceleration. If not, move with in-air acceleration
      @v.x += if @state is 'on-thing'
        if @v.x > 0
          Player.MOVE_ACC * dt
        else
          Player.FRICTION * dt
      else
        Player.MOVE_ACC_IN_AIR * dt

      # Constrain speed
      if @v.x >= Player.MAX_MOVE_SPEED
        @v.x = Player.MAX_MOVE_SPEED

    # Moving left. Same as moving right, but the other way
    else if keys.left && !@deactivated
      @v.x -= if @state is 'on-thing'
        if @v.x < 0
          Player.MOVE_ACC * dt
        else
          Player.FRICTION * dt
      else
        Player.MOVE_ACC_IN_AIR * dt

      if @v.x <= - Player.MAX_MOVE_SPEED
        @v.x = - Player.MAX_MOVE_SPEED

    # Not moving.
    else
      # If the object is moving right:
      if @v.x > 0
        # Slow it down. The rate depends on if it's on the ground or not
        @v.x -= if @state is 'on-thing' then Player.FRICTION else Player.FRICTION_IN_AIR

        # If it slows down so much it starts going the other way, stop it
        if @v.x < 0 then @v.x = 0

      # Repeat for moving left:
      else if @v.x < 0
        @v.x += if @state is 'on-thing' then Player.FRICTION else Player.FRICTION_IN_AIR
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
      @v.y = -Player.JUMP_SPEED
      @jump-frames = Player.MAX_JUMP_FRAMES
      @jump-state = \jumping
      @fall-dist = 0

    else if jump-key and jump-state is \jumping and state in <[jumping contact]> and jump-frames > 0
      @v.y = -Player.JUMP_SPEED
      @jump-frames -= dt
      @jump-state = \jumping
      @fall-dist = 0

    else if jump-key and jump-frames <= 0
      @jump-state = \stop

    else
      @jump-state = \ready
