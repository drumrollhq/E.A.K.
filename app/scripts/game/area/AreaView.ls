require! {
  'audio/music-manager'
  'game/actors/Player'
  'game/area/AreaLevel'
  'game/scene/AreaOverlay'
  'game/scene/BackgroundLayer'
  'game/scene/Camera'
  'game/scene/DomLayer'
  'game/scene/PlayerLayer'
  'game/scene/Scene'
  'game/scene/WebglLayer'
  'lib/channels'
}

const pad = 30px

module.exports = class AreaView extends Backbone.View
  initialize: ({@conf, @options, @prefix, @area}) ->
    @levels = @conf.levels.map (level) ~> new AreaLevel {level, @prefix}

    @camera = new Camera @conf.{width, height}, 0.1, 250
    @background-layer = new BackgroundLayer @conf.{width, height, name}
    @levels-layer = new DomLayer @conf.{width, height}
    @effects-layer = new WebglLayer @conf.{width, height}

    @layers = background: @background-layer, effects: @effects-layer, levels: @levels-layer

    @scene = new Scene @conf.{width, height}, @camera
    @scene.add-layers @background-layer, @levels-layer, @effects-layer

    # if @conf.overlay
      # @overlay = new AreaOverlay @conf.name, @conf.overlay, @conf.width, @conf.height, @effects-layer.renderer
      # @effects-layer.add @overlay, 5, true

    @window-sub = channels.window-size.subscribe ({width, height}) ~> @scene.set-viewport-size width, height
    @scene.set-viewport-size channels.window-size.value.width, channels.window-size.value.height

  # Load all area assets
  load: ->
    @background-layer.setup!
    Promise.all [
      @_load-levels!
      if @overlay then @overlay.setup!
    ]

  _load-levels: ->
    for level in @levels
      level.load!
      @levels-layer.add level, level.conf.{x, y}

  # Start playing with the state in 'store'
  start: (store) ->
    @stage-store = store
    Promise.map @levels, (level) ~> level.setup store, this
      .then ~>
        @add-player!
        @$el.append @scene.el
        @setup-sprite-sheets!
      .then ~> @$el.add-class \active

  setup-sprite-sheets: ->
    Promise.map @levels, ( .setup-sprite-sheets! )
      .reduce (a, b) -> a.concat b
      .each ([sprite-sheet, layer-name]) ~>
        @layers[layer-name].add sprite-sheet

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
    @levels-layer.add @player, {x, y}
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
    @check-edit-button level, false
    if level? and level isnt @player-level
      music-manager.switch-track (level.level.track or \normal)
      @player-level = level
      {x, y} = level.conf.player
      x += level.conf.x
      y += level.conf.y
      @player.set-origin x, y
      if level.conf.title isnt @stage-store.get \game.state.currentLocation
        @stage-store.patch-game-state current-location: level.conf.title
      @levels-layer.activate level

  check-edit-button: (level, urgent = true) ->
    if @_last-edit-button-checked is level and not urgent then return
    @_last-edit-button-checked = level
    if level? and level.editable!
      @show-edit-button!
    else
      @hide-edit-button!

  show-edit-button: ->
    $body.remove-class \hide-edit

  hide-edit-button: ->
    $body.add-class \hide-edit

  is-editable: ->
    unless @player-level? then return false
    @player-level.editable!

  editor-focus: (duration) ->
    for level in @levels when level isnt @player-level => level.hide!
    @player-level.focus!
    rect = {
      left: @player-level.conf.x
      top: @player-level.conf.y
      right: @player-level.conf.x + @player-level.conf.width
      bottom: @player-level.conf.y + @player-level.conf.height
      width: @player-level.conf.width
      height: @player-level.conf.height
    }

    frame-sub = channels.post-frame.subscribe ~> @scene.step!

    Promise.all [
      @background-layer.focus rect, duration
      @camera.start-edit-mode rect, duration, channels.post-frame
    ]
      .then ~>
        frame-sub.unsubscribe!
        @lock-edit-mode!

  editor-unfocus: (duration) ->
    @unlock-edit-mode!
    for level in @levels => level.show!
    @player-level.unfocus!

    frame-sub = channels.post-frame.subscribe ~> @scene.step!

    Promise.all [
      @background-layer.unfocus duration
      @camera.stop-edit-mode duration, channels.post-frame
    ]
      .then ~>
        frame-sub.unsubscribe!

  lock-edit-mode: ->
    @_edit-window-sub = channels.window-size.subscribe ({width, height}) ~>
      @camera.step!
      @scene.step!
      @$el.css left: \50%, overflow: \auto, width: width/2
      @scene.$el.css margin-left: -width / 2, overflow: \hidden

      scene-width = width/2 + Math.max @player-level.conf.width + 2*pad, width/2
      scene-height = Math.max @player-level.conf.height + 2*pad, height

      @scene.set-viewport-size scene-width, scene-height
      @camera.set-viewport width, height
      @scene.step!

    @_edit-window-sub.handler channels.window-size.value

  unlock-edit-mode: ->
    @_edit-window-sub.unsubscribe!
    @_edit-window-sub = null
    @$el
      ..scroll-top 0
      ..scroll-left 0
      ..css left: '', overflow: '', width: ''
    @scene.$el.css margin-left: '', overflow: ''

    {width, height} = channels.window-size.value
    @scene.set-viewport-size width, height
    @camera.set-viewport width, height
    @scene.step!
