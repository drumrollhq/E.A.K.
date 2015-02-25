require! {
  'game/actors/Actor'
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

box-burst-sprite = ->
  $ '<div></div>'
    ..attr {
      'data-sprite': '/content/sprites/kitten-box-burst.png'
      'data-sprite-start-frame': 0
      'data-sprite-frames': 14
      'data-sprite-loop': 1
      'data-sprite-state': 'paused'
      'data-sprite-size': '48x52'
      'data-sprite-speed': '0.025'
    }
    ..css 'display' 'none'
    ..add-class 'box-burst'

blink-sprite = ->
  $ '<div></div>'
    ..attr {
      'data-sprite': '/content/sprites/kitten-box-blink.png'
      'data-sprite-frames': 10
      'data-sprite-size': '48x52'
      'data-sprite-speed': '0.025'
      'data-sprite-delay': '0.1-6'
    }
    ..add-class 'box-blink'

module.exports = class KittenBox extends Actor
  @from-el = ($el, [x, y, kitten-id], offset = {x: 0, y: 0}, save-level) ->
    new KittenBox {
      x: offset.x + parse-float x
      y: offset.y + parse-float y
      el: $el.0
      offset: offset
      store: save-level
      kitten-id: kitten-id
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
    @render!
    @listen-to this, \contact:start:ENTITY_PLAYER, @touch-player

  render: ->
    @$el
      ..css left: @x - @offset.x, top: @y - @offset.y
      ..append random-kitten-el!
      ..append box-burst-sprite!
      ..append blink-sprite!

  touch-player: (player) ->
    unless @_saved then @save-me player

  save-me: (player) ->
    console.log 'save-me', @_saved
    @_saved = true
    if player.deactivated or player.last-fall-dist > player.fall-limit then return

    # Take out of physics engine:
    @destroy!

    # Log data and update save-game
    logger.log \kitten, player: player.{v, p}
    channels.kitten.publish {}
    @store.save-kitten @kitten-id

    # Hide blink animation
    blink = @$ \.box-blink
    blink.css display: \none
    blink-controller = blink.data \sprite-controller

    # Show box-burst animation
    burst = @$ \.box-burst
    burst.css display: \block
    burst-controller = burst.data \sprite-controller

    # Show burst animation
    burst-controller.restart!
    @$el.add-class \found

    # Clean up after animations
    @$el.find \.kitten-anim .one prefixed.animation-end, ~>
      burst-controller.remove!
      blink-controller.remove!
      @$el.remove!
