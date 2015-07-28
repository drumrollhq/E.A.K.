exports, require, module <- require.register 'minigames/urls/URLMiniGameView'

require! {
  'game/scene/Camera'
  'game/scene/Scene'
  'minigames/urls/GraphMap'
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
    @map = new GraphMap {
      width
      height
      map-url: '/content/bg-tiles/url-minigame/map'
      current-node: \phb
      nodes:
        phb: [1014, 1235, 'Ponyhead Bay']
        flee: [1439, 989, 'Flee']
        drudshire: [1266, 665, 'Drudshire']
        bulbous: [863, 444, 'Bulbous Island']
        shackerton: [602, 849, 'Shackerton-by-the-Sea']
        junction-phb: [1027, 965]
        junction-flee: [1240, 831]
        junction-drudshire: [1266, 752]
        junction-bulbous: [857, 545]
        junction-shackerton: [871, 852]
      paths: [
        [\phb \junction-phb [] []]
        [\flee \junction-flee [] []]
        [\drudshire \junction-drudshire [] []]
        [\bulbous \junction-bulbous [] []]
        [\shackerton \junction-shackerton [] []]
        [\junction-phb \junction-flee [] []]
        [\junction-flee \junction-drudshire [] []]
        [\junction-drudshire \junction-bulbous [] []]
        [\junction-bulbous \junction-shackerton [] []]
        [\junction-shackerton \junction-phb [] []]
      ]
    }
    @layer.add @map, 1, true
    @camera.track @map.player, true

  load: ->
    @map.setup!

  start: ->
    @$el
      .append @scene.el
      .add-class \active

  step: (t) ->
    @camera.step!
    @scene.step!
    @map.step t
