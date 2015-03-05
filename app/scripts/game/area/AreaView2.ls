require! {
  'animation/SpriteSheet'
  'game/actors/Player'
  'game/area/AreaLevel'
  'game/scene/BackgroundLayer'
  'game/scene/Camera'
  'game/scene/DomLayer'
  'game/scene/PlayerLayer'
  'game/scene/Scene'
  'lib/channels'
}

module.exports = class AreaView2 extends Backbone.View
  initialize: ({@conf, @options, @prefix}) ->
    @levels = @conf.levels.map (level) ~> new AreaLevel {level, @prefix}

    @camera = new Camera @conf.{width, height}, 0.2, 250
    @background-layer = new BackgroundLayer @conf.{width, height, name}
    @player-layer = new DomLayer @conf.{width, height}
    @levels-layer = new DomLayer @conf.{width, height}

    @scene = new Scene @conf.{width, height}, @camera
    @scene.add-layers @background-layer, @levels-layer, @player-layer

    @window-sub = channels.window-size.subscribe ({width, height}) ~> @scene.set-viewport-size width, height
    @scene.set-viewport-size channels.window-size.value.width, channels.window-size.value.height

  # Load all area assets
  load: ->
    Promise.all [
      @_load-levels!
      @background-layer.load!
    ]

  _load-levels: ->
    Promise.map @levels, (level) ~>
      level.load! .then ~>
        @levels-layer.add level, level.conf.{x, y}

  # Start playing with the state in 'store'
  start: (store) ->
    @stage-store = store
    for level in @levels => level.setup store
    @add-player!
    @$el.append @scene.el
    @setup-sprite-sheets! .then ~>
      @$el.add-class \active

  setup-sprite-sheets: ->
    Promise.map (@$ '[data-sprite]' .to-array!), SpriteSheet.create

  remove: ->
    @window-sub.unsubscribe!
    for level in @levels => level.remove!
    @scene.remove include-layers: true
    @stop-listening!
    @$el
      ..remove-class \active
      ..add-class \remove
      ..one prefixed.animation-end, ~>
        @$el.remove-class \remove

  initial-player-pos: ->
    {x, y} = @levels.0.conf.player
    x += @levels.0.conf.x
    y += @levels.0.conf.y
    {x, y}

  add-player: ->
    if @player? then return @player

    {x, y} = (if @options?.x? then @options.{x, y}) or
      (@stage-store.get \stage.state.playerPos) or
      @initial-player-pos!

    x = parse-float x
    y = parse-float y
    @player = new Player {x, y, store: @stage-store}
    @player-layer.add @player, {x, y}
    @camera.track @player

  build-map: ->
    for level in @levels => level.create-map @camera.offset-y, @camera.offset-x
    nodes = @levels |> map ( .map ) |> flatten
    nodes[*] = @player or @add-player!
    nodes

  step: ->
    @check-player-is-in-world!
    @update-player-level!
    @camera.step!
    @scene.step!

  check-player-is-in-world: ->
    unless @scene.contains @player.p.x, @player.p.y, 200
      channels.death.publish cause: \fall-out-of-world

  update-player-level: ->
    level = @levels-layer.object-at @player.p
    if level? and level isnt @player-level
      @player-level = level
      {x, y} = level.conf.player
      x += level.conf.x
      y += level.conf.y
      @player.set-origin x, y
      @levels-layer.activate level
      if level.conf.editable then $body.remove-class \hide-edit else $body.add-class \hide-edit
