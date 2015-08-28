exports, require, module <- require.register 'minigames/urls/Zoomer'

require! {
  'lib/math/ease'
}

const transition-speed = 1000ms

module.exports = class ZoomingMap extends PIXI.Container
  (@camera, @player, @main, @sub-levels, @preserve-player-position = false) ->
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
      @add-child sub-level
      sub-level.visible = false
      sub-level.alpha = 0

  step: (t) ->
    if @_player-transitioning
      @_player-transition-time += t
      d = Math.min 1, @_player-transition-time / @_player-duration
      @player.target-scale = ease.lerp @_player-from.scale, @_player-to.scale, ease.sin d
      @player.x = ease.lerp @_player-from.x, @_player-to.x, ease.sin d
      @player.y = ease.lerp @_player-from.y, @_player-to.y, ease.sin d

      if d is 1
        @_player-transitioning = false

    if @_level-transitioning
      @_level-transition-time += t
      d = Math.min 1, @_level-transition-time / @_level-duration
      @_level-transitioning.alpha = ease.lerp @_level-from, @_level-to, ease.sin d

      if d is 1
        @_level-transitioning = false

  zoom-to: (name, {start-pos = @initial-sub-levels[name].start, activate = true, emit = true} = {}) ->
    if @_zooming then return
    prevent = false
    if emit then @emit \before-zoom-in, name, -> prevent := true
    if prevent then return
    @_zooming = true

    level = @sub-levels[name]
    initial = @initial-sub-levels[name]
    @active-name = name
    level.visible = true

    @_player-return = @player.{x, y}

    @animate-player {
      scale: level.player-scale
      x: initial.x + initial.scale * start-pos.x
      y: initial.y + initial.scale * start-pos.y
    }, transition-speed

    @animate-sub-level-alpha level, 1, transition-speed

    @camera.set-subject start-pos
    [tx, ty] = @camera.centered!
    tx = initial.x + initial.scale * tx
    ty = initial.y + initial.scale * ty

    @main.deactivate! if @main.deactivate
    @camera.animate-to tx, ty, 1/initial.scale, transition-speed

    # Promise.delay 1000/16
      # .then ~> @camera.animate-to tx, ty, 1/initial.scale, transition-speed
      .then ~>
        @active = level
        @main.visible = false

        level.scale.x = level.scale.y = 1
        level <<< x: 0, y: 0
        level.visible = true
        @player <<< start-pos.{x, y}

        @camera.set-zoom 1, false
        @camera.set-subject @player
        [tx, ty] = @camera.centered!
        @camera.set-position tx, ty, false

        if activate
          level.activate! if level.activate
          level.on \exit, exit-handler = ~>
            if @zoom-out! isnt \prevented then level.off \exit, exit-handler
          level.on \path, @_path-handler = (...args) ~> @emit \path, ...args
        @_zooming = false
        if emit then @emit \zoom-in, name

  zoom-out: ({activate = true, emit = true, pos} = {}) ~>
    if @_zooming then return
    prevent = false
    if emit then @emit \before-zoom-out, -> prevent := true
    if prevent then return \prevented
    @_zooming = true

    level = @active
    initial = @initial-sub-levels[@active-name]
    @active = @main

    level
      ..off \path, @_path-handler
      ..deactivate! if level.deactivate
      ..scale <<< x: initial.scale, y: initial.scale
      ..position <<< initial.{x, y}
      ..set-viewport 0, 0, initial.width, initial.height

    @main.visible = true

    @player.x = initial.x + initial.scale * @player.x
    @player.y = initial.y + initial.scale * @player.y

    if pos
      px = pos.x
      py = pos.y
    else if @preserve-player-position
      px = @_player-return.x
      py = @_player-return.y
    else
      px = @player.x
      py = @player.y

    @animate-player {
      scale: @main.player-scale
      x: px
      y: py
    }, transition-speed

    @animate-sub-level-alpha level, 0, transition-speed

    @camera.set-subject x: px, y: py
    [tx, ty] = @camera.centered!

    x = initial.x + initial.scale * @camera.offset-x
    y = initial.y + initial.scale * @camera.offset-y
    @camera.animate-to x, y, 1 / initial.scale, false

    @camera.animate-to tx, ty, 1, transition-speed
      .then ~>
        @active-name = null
        @active.activate! if @active.activate and activate
        level.visible = false
        @_zooming = false
        if emit then @emit \zoom-out

  animate-player: (player-to, duration) ->
    @_player-transitioning = true
    @_player-from = {scale: @player.target-scale, x: @player.x, y: @player.y}
    @_player-to = player-to
    @_player-transition-time = 0
    @_player-duration = duration

  animate-sub-level-alpha: (level, alpha, duration) ->
    @_level-transitioning = level
    @_level-from = level.alpha
    @_level-to = alpha
    @_level-transition-time = 0
    @_level-duration = duration

  set-viewport: (top, left, bottom, right) ->
    @active.set-viewport top, left, bottom, right
