exports, require, module <- require.register 'minigames/urls/Zoomer'

require! {
  'lib/math/ease'
}

const transition-speed = 1000ms

module.exports = class ZoomingMap extends PIXI.Container
  (@camera, @player, @main, @sub-levels) ->
    super!
    @active = @main
    @add-child @main
    @initial-sub-levels = @sub-levels |> Obj.map (level) -> {
      x: level.x
      y: level.y
      scale: level.scale.x
      start: level.start.{x, y}
      width: level.full-width
      height: level.full-height
    }

    for _, sub-level of @sub-levels
      sub-level.cache-as-bitmap = true
      @add-child sub-level

  step: (t) ->
    if @_player-transitioning
      @_player-transition-time += t
      d = Math.min 1, @_player-transition-time / @_player-duration
      @player.target-scale = ease.lerp @_player-from.scale, @_player-to.scale, ease.sin d
      @player.x = ease.lerp @_player-from.x, @_player-to.x, ease.sin d
      @player.y = ease.lerp @_player-from.y, @_player-to.y, ease.sin d

      if d is 1
        @_player-transitioning = false

  zoom-to: (name) ->
    if @_zooming then return
    @_zooming = true

    level = @sub-levels[name]
    initial = @initial-sub-levels[name]
    @active = level
    @active-name = name

    @_player-return = @player.{x, y}

    @animate-player {
      scale: level.player-scale
      x: initial.x + initial.scale * initial.start.x
      y: initial.y + initial.scale * initial.start.y
    }, transition-speed

    @camera.set-subject initial.start
    [tx, ty] = @camera.centered!
    tx = initial.x + initial.scale * tx
    ty = initial.y + initial.scale * ty

    @main.deactivate!

    @camera.animate-to tx, ty, 1/initial.scale, transition-speed
      .then ~>
        @main.visible = false
        for _, l of @sub-levels => l.visible = false

        level.scale.x = level.scale.y = 1
        level <<< x: 0, y: 0, cache-as-bitmap: false
        level.visible = true
        @player <<< initial.start.{x, y}

        @camera.set-zoom 1, false
        @camera.set-subject @player
        [tx, ty] = @camera.centered!
        @camera.set-position tx, ty, false

        level.activate!
        level.once \exit, ~> @zoom-out!
        level.on \path (...args) ~> @emit \path, ...args
        @_zooming = false
        @emit \zoom-in

  zoom-out: ~>
    if @_zooming then return
    @_zooming = true

    level = @active
    initial = @initial-sub-levels[@active-name]
    @active = @main

    level
      ..deactivate!
      ..scale <<< x: initial.scale, y: initial.scale
      ..position <<< initial.{x, y}
      ..set-viewport 0, 0, initial.width, initial.height
      ..cache-as-bitmap = true

    @main.visible = true
    for _, l of @sub-levels => l.visible = true

    @player.x = initial.x + initial.scale * @player.x
    @player.y = initial.y + initial.scale * @player.y

    x = initial.x + initial.scale * @camera.offset-x
    y = initial.y + initial.scale * @camera.offset-y
    @camera.animate-to x, y, 1 / initial.scale, false

    @animate-player {
      scale: @main.player-scale
      x: @_player-return.x
      y: @_player-return.y
    }, transition-speed

    @camera.set-subject @_player-return
    [tx, ty] = @camera.centered!

    @camera.animate-to tx, ty, 1, transition-speed
      .then ~>
        @active-name = null
        @active.activate!
        @camera.track @player, true
        @_zooming = false
        @emit \zoom-out

  animate-player: (player-to, duration) ->
    console.log 'animate-player', player-to
    @_player-transitioning = true
    @_player-from = {scale: @player.target-scale, x: @player.x, y: @player.y}
    @_player-to = player-to
    @_player-transition-time = 0
    @_player-duration = duration

  set-viewport: (top, left, bottom, right) ->
    @active.set-viewport top, left, bottom, right
