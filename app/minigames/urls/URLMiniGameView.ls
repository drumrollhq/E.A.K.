exports, require, module <- require.register 'minigames/urls/URLMiniGameView'

require! {
  'game/scene/Camera'
  'game/scene/Scene'
  'game/scene/TiledSpriteContainer'
  'game/scene/WebglLayer'
  'lib/channels'
}

module.exports = class URLMiniGameView extends Backbone.View
  initialize: ->
    [width, height] = [2000, 1800]

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
    @map = new TiledSpriteContainer '/content/bg-tiles/url-minigame/map', width, height
    @layer.add @map, 1, true

  load: ->
    @map.setup!

  start: ->
    @$el
      .append @scene.el
      .add-class \active

  step: ->
    @camera.step!
    @scene.step!
