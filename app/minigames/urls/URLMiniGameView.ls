exports, require, module <- require.register 'minigames/urls/URLMiniGameView'

require! {
  'game/scene/Camera'
  'game/scene/Scene'
  'game/scene/WebglLayer'
  'lib/channels'
  'lib/math/ease'
  'minigames/urls/components/URLDisplay'
  'minigames/urls/GraphMap'
  'minigames/urls/WalkingMap'
  'minigames/urls/maps'
}

const width = 2000px
const height = 1800px
const town-scale = 0.12
const player-scale = 0.6
const player-scale-walking = 0.4
const transition-speed = 1000ms

module.exports = class URLMiniGameView extends Backbone.View
  initialize: ->

    # Basic camera+scene boilerplate
    @camera = new Camera {width, height}, 0.1, -300
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

    @map.on \arrive, (loc) ~>
      domain = @map.graph[loc].domain
      @url-component.set-state actual: [\http, domain]
      if @towns[loc] then @zoom-in loc

  load: ->
    @map.setup!
    for name, town of @towns
      town
        ..setup!
        ..set-viewport 0, 0, width, height
        ..cache-as-bitmap = true

    @$react-cont = $ '<div class="url-cont"></div>'
    @url-component = React.render (React.create-element URLDisplay), @$react-cont.0

  start: ->
    @$el
      .append @scene.el
      .append @$react-cont
      .add-class \active

    @map.activate!

  set-target-url: (protocol, domain, ...path) ->
    @url-component.set-state target: [protocol, domain, ...path]

  set-actual-path: (path) ->
    @has-set-path = true
    if path is @_last-path-set then return
    @_last-path-set = path

    if path?
      parts = path.split '/'
    else
      parts = []

    console.log 'setting path' parts, @_last-path-set, path
    @url-component.set-state actual: [@url-component.state.actual.0, @url-component.state.actual.1, ...parts]

  step: (t) ->
    @camera.step t
    @scene.step t
    @map.step t
    @has-set-path = false
    for _, town of @towns => town.step t
    unless @has-set-path then @set-actual-path null

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
    if @_zooming then return
    @_zooming = true
    town = @towns[town-name]
    @current-town = town-name

    @animate-player {
      scale: player-scale-walking
      x: town.x + town.start.x * town.scale.x
      y: town.y + town.start.y * town.scale.y
    }, transition-speed

    @camera.set-subject town.start
    [tx, ty] = @camera.centered!
    tx = town.x + town.scale.x * tx
    ty = town.y + town.scale.y * ty

    @map.deactivate!

    @camera.animate-to tx, ty, 1 / town-scale, transition-speed
      .then ~>
        @layer.remove @map
        for _, remove-town of @towns
          @layer.remove remove-town

        town.scale.x = town.scale.y = 1
        town <<< x: 0, y: 0, cache-as-bitmap: false
        @layer.add town, 2, true
        @player <<< town.start.{x, y}

        @camera.set-zoom 1, 0
        @camera.set-subject @player
        [tx, ty] = @camera.centered!
        @camera.set-position tx, ty, 0

        town.activate!
        town.once \exit, ~> @zoom-out!
        town.on \path, (path) ~> @set-actual-path path
        @_zooming = false

  zoom-out: ~>
    if @_zooming then return
    @_zooming = true
    town = @towns[@current-town]
      ..deactivate!
      ..scale <<< x: town-scale, y: town-scale
      ..position <<< x: maps.towns[@current-town].0, y: maps.towns[@current-town].1
      ..set-viewport 0, 0, width, height
      ..cache-as-bitmap = true

    @layer.remove town
    @layer.add @map, 1, true
    for _, _town of @towns => @layer.add _town, 2, false

    @player.x = town.x + town.scale.x * @player.x
    @player.y = town.y + town.scale.y * @player.y

    x = town.x + town.scale.x * @camera.offset-x
    y = town.y + town.scale.y * @camera.offset-y
    @camera.animate-to x, y, 1 / town-scale, false

    @animate-player {
      scale: player-scale
      x: @map.graph[@current-town].position.x
      y: @map.graph[@current-town].position.y
    }, transition-speed

    @camera.set-subject @map.graph[@current-town].position
    [tx, ty] = @camera.centered!

    @camera.animate-to tx, ty, 1, transition-speed
      .then ~>
        @current-town = null
        @map.activate!
        @map.exit!
        @camera.track @player, true
        @_zooming = false

  animate-player: (player-to, duration) ->
    @_player-transitioning = true
    @_player-from = {scale: @_player-scale, x: @player.x, y: @player.y}
    @_player-to = player-to
    @_player-transition-time = 0
    @_player-duration = duration
