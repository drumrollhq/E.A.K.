require! {
  'game/actors/Actor'
  'game/effects/ParticleEmitter'
  'game/effects/SpriteSet'
  'lib/channels'
  'lib/keys'
  'lib/math/Vector'
  'lib/math/ease': {lerp}
}

particle-def = {
  url: '/content/particles/space-pulse.png'
  rate: [15 20]
  lifetime: [100 150]
  y: (age) -> age / 5
  scale: (age, lifetime) -> 0.3 + 0.3 * (age/lifetime)
  alpha: (age, lifetime) ->
    p = age / lifetime
    if p < 0.4 then p * 2.5
    else 1 - (p - 0.4) * 1.666
}

animations =
  push: [<[push]>]
  flex:
    * <[flexRaise flexLower]>
    * <[flexRaise flex flexLower]>
    * <[flexRaise flex flex flexLower]>
    * <[flexRaise flex flex flex flexLower]>

places =
  * p: new Vector 1000, 800
    animations: animations.push
    right: false
  * p: new Vector 700, 840
    animations: animations.push
    right: true
  * p: new Vector 1180, 1120
    animations: animations.flex
    right: true
  * p: new Vector 300, 900
    animations: animations.flex
    right: false

finished-place = do
  p: new Vector 1600, 690
  animations: animations.flex
  right: true

class TarquinSpaceship extends Actor
  physics: {
    data:
      dynamic: true
      ignore-others: true
      sensor: true
    width: 55
    height: 100
  }

  @MAX_MOVE_SPEED = 4px
  @ACCELERATION = 0.1
  @DIRECTION_CHANGE_SPEED = 0.3px
  @ARRIVE_THRESHOLD = 30

  initialize: (start) ->
    @start = start
    start <<< start.offset.{x, y}
    start.y += 100
    start.x += 150
    super start
    window.tarquin = this
    @sprite-set = new SpriteSet {
      main: \relaxed
      sprites:
        relaxed: ['/entities/tarquin-spaceship/sprites/tarquin-relaxed' 110 140 0 0 speed: 15]
        push: ['/entities/tarquin-spaceship/sprites/tarquin-push' 110 140 0.5 -0.5 speed: 15]
        flex-raise: ['/entities/tarquin-spaceship/sprites/tarquin-flex-raise' 110 140 5.5 0 speed: 15]
        flex: ['/entities/tarquin-spaceship/sprites/tarquin-flex' 110 140 6 0 speed: 15]
        flex-lower: ['/entities/tarquin-spaceship/sprites/tarquin-flex-lower' 110 140 5.5 -0.5 speed: 15]
    }
    @sprite-set <<< start.offset.{x, y}

    @waiting-mode = false
    @_error-sub = channels.parse \triggers:error-change .subscribe @check-mode.bind this

    @emitter = new ParticleEmitter new Vector!, particle-def
    @v = new Vector!
    @_t = 0
    @choose-target-location!

    @render!

  render: ->
    @$el.css {
      position: \absolute
      width: TarquinSpaceship::physics.width
      height: TarquinSpaceship::physics.height
      top: @start.y
      left: @start.x
      margin-left: -30px
      margin-top: 10px
    }

  load: ->
    sprite = @sprite-set.load!
      .then ~> @area-view.effects-layer.add @sprite-set, 3

    emitter = @emitter.load!
      .then ~> @area-view.background-layer.add @emitter

    Promise.all [sprite, emitter]

  remove: ->
    super!
    @_error-sub.unsubscribe!

  check-mode: ->
    no-errors = @area-view.levels
      |> filter ( .has-errors )
      |> empty

    if no-errors and not @store.get \state.tarquinSaidGoodbye
      @start-waiting-mode!
    else
      @stop-waiting-mode!

  start-waiting-mode: ->
    if @waiting-mode then return
    @waiting-mode = true
    @listen-to-once this, \contact:start:ENTITY_PLAYER, ~>
      eak.start-conversation "/#{EAK_LANG}/areas/2-spaceship/spaceship-fixed"

  stop-waiting-mode: ->
    unless @waiting-mode then return
    @waiting-mode = false
    @stop-listening this, \contact:start:ENTITY_PLAYER
    @choose-target-location 0

  choose-target-location: (i = Math.floor Math.random! * places.length) ->
    i = Math.floor Math.random! * places.length
    if @_target-place-i is i then return @choose-target-location!
    @_target-place-i = i
    @_target = places[i].p
    @_target-right = places[i].right

    @_reached-x = @_reached-y = false

  step: (t) ->
    if @waiting-mode
      @p <<< finished-place.p.{x, y}
      @_t += t
      @p.y += 5 * Math.sin @_t / 50
      @v <<< x: 0, y: 0
      @looking-right = finished-place.right
      @_reached-x = @_reached-y = true
    else
      x-dist = if @_reached-x then 0 else @_target.x - @p.x
      y-dist = if @_reached-y then 0 else @_target.y - @p.y

      target-vx = if x-dist < -TarquinSpaceship.ARRIVE_THRESHOLD then -TarquinSpaceship.MAX_MOVE_SPEED
        else if x-dist > TarquinSpaceship.ARRIVE_THRESHOLD then TarquinSpaceship.MAX_MOVE_SPEED
        else if @looking-right is @_target-right
          @_reached-x = true
          0
        else if @_target-right then TarquinSpaceship.MAX_MOVE_SPEED
        else -TarquinSpaceship.MAX_MOVE_SPEED
      target-vy = if y-dist < -TarquinSpaceship.ARRIVE_THRESHOLD then -TarquinSpaceship.MAX_MOVE_SPEED
        else if y-dist > TarquinSpaceship.ARRIVE_THRESHOLD then TarquinSpaceship.MAX_MOVE_SPEED
        else
          @_reached-y = true
          0

      @v.x = lerp @v.x, target-vx, TarquinSpaceship.ACCELERATION
      @v.y = lerp @v.y, target-vy, TarquinSpaceship.ACCELERATION

      @looking-right = if @v.x > TarquinSpaceship.DIRECTION_CHANGE_SPEED then true else if @v.x < -TarquinSpaceship.DIRECTION_CHANGE_SPEED then false else @looking-right

    @emitter.step t

  after-physics: ->
    if @_reached-x and @_reached-y and not @_animating
      @_animating = true
      anim = _.sample if @waiting-mode then finished-place.animations else places[@_target-place-i].animations
      @sprite-set.queue ...anim
        .then ~>
          @_animating = false
          @choose-target-location!

  draw: ->
    super!
    if @looking-right
      @sprite-set.scale.x = -1
      @sprite-set.x = @p.x + 50
      @emitter.emitter.x = @p.x - 12
    else
      @sprite-set.scale.x = 1
      @sprite-set.x = @p.x - 55
      @emitter.emitter.x = @p.x + 7

    @sprite-set.y = @p.y - 70
    @emitter.emitter.y = @p.y + 45

eak.register-actor TarquinSpaceship
