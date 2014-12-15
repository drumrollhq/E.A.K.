require! {
  'channels'
  'game/physics/keys'
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

module.exports = class Player extends Backbone.View
  tag-name: \div
  class-name: 'player entity'

  initialize: (start = {x: 0, y: 0, colour: 'white'}) ->
    @el.width = 33px
    @el.height = 54px
    @subs = []
    @start = start
    @origin = start.{x, y}

    @$el.add-class "player-colour-#{start.colour}"
    @$el.html player-html
    @$inner-el = @$el.find '.player-inner'

    @$el.attr \data-ignore true
    @$el.css {
      position: \absolute
      left: start.x - @el.width/2
      top: start.y - @el.height/2
    }

    @last-classes = []
    @last-direction = 'right'
    @classes-disabled = false

    # Data for physics engine:
    @ <<< {
      type: 'rect'
      x: start.x
      y: start.y
      width: @el.width
      height: @el.height
      rotation: 0
      data:
        player: true
        id: 'ENTITY_PLAYER'
    }

    @subs[*] = channels.death.filter ( .cause is 'fall-out-of-world' ) .subscribe ~> @reset!
    @subs[*] = channels.death.filter ( .cause is 'fall-to-death' ) .subscribe @fall-to-death
    @subs[*] = channels.post-frame.subscribe @calc-classes
    @subs[*] = channels.death.subscribe (death) ~>
      logger.log 'death', {cause: death.cause, data: death.data, player: @{p, v}}

  reset: (origin = @origin) ~>
    @ <<< {
      x: origin.x
      y: origin.y
      rotation: 0
      prepared: false
    }

    @$el.css {
      left: origin.x - @el.width/2
      top: origin.y - @el.height/2
    }

    @prepare!

  remove: ~>
    super!
    for sub in @subs => sub.unsubscribe!

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

      @apply-classes classes

  apply-classes: (classes) ~>
    for classname in @last-classes
      if classname not in classes then @$el.remove-class "player-#classname"

    for classname in classes
      if classname not in @last-classes then @$el.add-class "player-#classname"

    @last-classes := classes

  draw: ->
    @apply-classes []
    @$el.css prefixed.transform, "translate3d(#{@p.x - @x}px, #{@p.y - @y}px, 0)"


  fall-to-death: ~>
    @apply-classes ['squish' @last-direction]
    @deactivated = true
    @classes-disabled = true
    <~ set-timeout _, 1500
    @classes-disabled = false
    @deactivated = false
    @reset!
