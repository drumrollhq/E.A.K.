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
      exit: true
      nodes:
        phb: [1014 1235 'to Ponyhead\nBay' -50 -210]
        flee: [1439 989 'to Flee' -185 -110]
        drudshire: [1266 665 'to Drudshire' -70 20]
        bulbous: [863 444 'to Bulbous\nIsland' -70 15]
        shackerton: [602 849 'to Shackerton\nby-the-Sea' 70 -55]
        junction-phb: [1027 965]
        junction-flee: [1240 831]
        junction-drudshire: [1266 752]
        junction-bulbous: [857 545]
        junction-shackerton: [871 852]
      paths: [
        [\phb \junction-phb [1047 1172] [1027 965]]
        [\flee \junction-flee [1239 1002] [1313 863]]
        [\drudshire \junction-drudshire [1271 719] [1266 752]]
        [\bulbous \junction-bulbous [830 488] [857 545]]
        [\shackerton \junction-shackerton [602 849] [774 792]]
        [\junction-phb \junction-flee [1137 966] [1157 832]]
        [\junction-flee \junction-drudshire [1240 831] [1263 785]]
        [\junction-drudshire \junction-bulbous [1097 718] [1045 459]]
        [\junction-bulbous \junction-shackerton [935 731] [843 771]]
        [\junction-shackerton \junction-phb [871 852] [972 938]]
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
