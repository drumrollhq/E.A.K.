exports, require, module <- require.register 'minigames/urls/URLMiniGameView'

require! {
  'game/scene/Camera'
  'game/scene/Scene'
  'game/scene/WebglLayer'
  'lib/channels'
  'lib/math/ease'
  'minigames/urls/GraphMap'
  'minigames/urls/WalkingMap'
  'minigames/urls/maps'
}

const width = 2000px
const height = 1800px
const town-scale = 0.12
const player-scale = 0.6
const player-scale-walking = 0.4

module.exports = class URLMiniGameView extends Backbone.View
  initialize: ->

    # Basic camera+scene boilerplate
    @camera = new Camera {width, height}, 0.1, 100
    @layer = new WebglLayer {width, height}
    @scene = new Scene {width, height}, @camera
    @scene.add-layers @layer

    # Make sure the scene and camera keep track of the window size
    @scene.set-viewport-size channels.window-size.value.width, channels.window-size.value.height
    @window-sub = channels.window-size.subscribe ({width, height}) ~>
      @scene.set-viewport-size width, height

    @player = new PIXI.Sprite.from-image '/minigames/urls/assets/arca-head.png', \url
    @player.anchor <<< x: 0.5, y: 0.5
    @player <<< width: 60 * player-scale, height: 55 * player-scale
    @layer.add @player, 4
    @_player-scale = player-scale

    # Map:
    @map = new GraphMap @layer, @player, maps.main-map <<< {
      width
      height
      current-node: \junctionBulbous
      exit: false
    }

    @towns = {}
    for name, [x, y] of maps.towns
      town = new WalkingMap @layer, @player, maps[name] <<< {width, height}
        ..scale <<< x: town-scale, y: town-scale
        ..position <<< {x, y}

      @layer.add town, 2, false
      @towns[name] = town

    @layer.add @map, 1, true
    @camera.track @map.player, true

    @map.on \arrive, (town) ~> if @towns[town] then @zoom-in town

  load: ->
    @map.setup!
    for name, town of @towns
      town
        ..setup!
        ..set-viewport 0, 0, width, height
        ..cache-as-bitmap = true

  start: ->
    @$el
      .append @scene.el
      .add-class \active

    @map.activate!

  step: (t) ->
    @camera.step t
    @scene.step t
    @map.step t
    for _, town of @towns => town.step t

    if @_player-transitioning
      @_player-transition-time += t
      d = Math.min 1, @_player-transition-time / @_player-duration
      @_player-scale = ease.lerp @_player-from.scale, @_player-to.scale, ease.sin d
      @player.x = ease.lerp @_player-from.x, @_player-to.x, ease.sin d
      @player.y = ease.lerp @_player-from.y, @_player-to.y, ease.sin d

      if d is 1
        @_player-transitioning = false

    @player.width = 60 * @_player-scale / @camera.zoom
    @player.height = 55 * @_player-scale / @camera.zoom

  zoom-in: (town-name) ->
    transition-speed = 1000ms
    town = @towns[town-name]

    @_player-transitioning = true
    @_player-from = {scale: @_player-scale, x: @player.x, y: @player.y}
    @_player-to = {
      scale: player-scale-walking
      x: town.x + town.start.x * town.scale.x
      y: town.y + town.start.y * town.scale.y
    }
    @_player-transition-time = 0
    @_player-duration = transition-speed

    @camera.set-subject town.start
    [tx, ty] = @camera.centered!
    tx = town.x + town.scale.x * tx
    ty = town.y + town.scale.y * ty

    @map.deactivate!

    @camera.animate-to tx, ty, 1 / town-scale, transition-speed
      .then ~>
        @layer.remove @map
        for _, remove-town of @towns when remove-town isnt town
          @layer.remove remove-town

        town.scale.x = town.scale.y = 1
        town <<< x: 0, y: 0
        @player <<< town.start.{x, y}
        @camera.set-zoom 1, 0
        @camera.set-subject @player
        [tx, ty] = @camera.centered!
        @camera.set-position tx, ty, 0

        town.activate!
