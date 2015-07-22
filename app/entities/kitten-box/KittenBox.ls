require! {
  'game/actors/Actor'
  'game/effects/SpriteSheet'
  'logger'
  'lib/channels'
}

const available-kittens = 147

random-kitten = ->
  "url('/content/kittens/kitten-#{ (Math.random! * available-kittens |> Math.floor) + 1 }.gif')"

random-kitten-el = ->
  $ '<div></div>'
    ..css 'background-image', random-kitten!
    ..add-class 'kitten-anim'

box-burst-sprite = (av, x, y) ->
  sprite = new SpriteSheet '/entities/kitten-box/sprites/kitten-box-burst', 48, 52, x - 24, y - 26, {
    speed: 30
    loop-times: 1
    state: \paused
  }

blink-sprite = (av, x, y) ->
  sprite = new SpriteSheet '/entities/kitten-box/sprites/kitten-box-blink', 48, 52, x - 24, y - 26, {
    speed: 30
    delay: [0.1, 6]
  }

class KittenBox extends Actor
  @from-el = ($el, [x, y, kitten-id], offset = {x: 0, y: 0}, save-level, area-view) ->
    new KittenBox {
      x: offset.x + parse-float x
      y: offset.y + parse-float y
      el: $el.0
      offset: offset
      store: save-level
      kitten-id: kitten-id
      area-view: area-view
    }

  physics:
    width: 48px
    height: 52px
    data:
      dynamic: false
      sensor: true

  initialize: (options) ->
    super options
    @kitten-id = options.kitten-id
    @area-view = options.area-view
    @render!
    @listen-to this, \contact:start:ENTITY_PLAYER, @touch-player

  render: ->
    @$el
      ..css left: @x - @offset.x, top: @y - @offset.y
      ..append random-kitten-el!

    @box-burst-sprite = box-burst-sprite @area-view, @x, @y
    @box-burst-sprite.visible = true
    @blink-sprite = blink-sprite @area-view, @x, @y

  load: ->
    Promise.all [
      @box-burst-sprite.load!
      @blink-sprite.load!
    ] .then ~>
      @area-view.effects-layer.add @box-burst-sprite
      @area-view.effects-layer.add @blink-sprite

  touch-player: (player) ->
    unless @_saved then @save-me player

  save-me: (player) ->
    @_saved = true
    if player.deactivated or player.last-fall-dist > player.fall-limit then return

    # Take out of physics engine:
    @destroy!

    # Log data and update save-game
    logger.log \kitten, player: player.{v, p}
    channels.kitten.publish {}
    @store.save-kitten @kitten-id

    # Hide blink animation
    @blink-sprite.stop!
    @blink-sprite.visible = false

    # Show box-burst animation
    @box-burst-sprite.visible = true
    @box-burst-sprite.goto-and-play 0
    @$el.add-class \found
    Promise.delay 1000
      .then ~> @box-burst-sprite.animate 1000, (amt) -> @alpha = 1 - amt
      .then ~> @box-burst-sprite.visible = false

    # Clean up after animations
    @$el.find \.kitten-anim .one prefixed.animation-end, ~>
      @$el
        ..empty!
        ..remove!

eak.register-actor KittenBox
