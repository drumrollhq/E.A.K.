exports, require, module <- require.register 'minigames/urls/URLMiniGameView'

require! {
  'game/scene/Camera'
  'game/scene/Scene'
  'game/scene/WebglLayer'
  'lib/channels'
  'minigames/urls/GraphMap'
  'minigames/urls/WalkingMap'
  'minigames/urls/maps'
}

const width = 2000px
const height = 1800px
const town-scale = 0.12

module.exports = class URLMiniGameView extends Backbone.View
  initialize: ->

    # Basic camera+scene boilerplate
    @camera = new Camera {width, height}, 0.1, 250
    @layer = new WebglLayer {width, height}
    @scene = new Scene {width, height}, @camera
    @scene.add-layers @layer

    # Make sure the scene and camera keep track of the window size
    @scene.set-viewport-size channels.window-size.value.width, channels.window-size.value.height
    @window-sub = channels.window-size.subscribe ({width, height}) ~>
      @scene.set-viewport-size width, height

    # Map:
    @map = new GraphMap maps.main-map <<< {
      width
      height
      current-node: \phb
      exit: true
    }

    @towns = {}
    for name, [x, y] of maps.towns
      town = new WalkingMap maps[name] <<< {width, height}
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

  step: (t) ->
    @camera.step t
    @scene.step t
    @map.step t

  zoom-in: (town-name) ->
    town = @towns[town-name]
    @camera.set-subject town.start
    target = @camera.centered!
    @camera.set-zoom 1 / town-scale
    # @camera.zoom-to town, target

