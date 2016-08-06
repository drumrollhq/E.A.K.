exports, require, module <- require.register 'minigames/urls/LocationIndicator'

require! {
  'lib/math/ease'
}

const green = 0x2ecc71
const period = 700ms

get-circle = (x, y, radius, colour, alpha = 1) ->
  new PIXI.Graphics!
    ..x = x
    ..y = y
    ..begin-fill colour, alpha
    ..draw-circle 0, 0, radius
    ..end-fill!

module.exports = class LocationIndicator extends PIXI.Container
  (x, y, @visible = true) ->
    super!
    @t = 0
    @circle = get-circle 0, 0, 10, green, 0.5
    @pulser = get-circle 0, 0, 35, green
    @add-child @circle
    @add-child @pulser
    @position <<< {x, y}

  step: (delta) ~>
    @t += delta
    @pulser.scale.x = @pulser.scale.y = @get-scale (@t % period) / period
    @pulser.alpha = @get-alpha (@t % period) / period

  get-scale: (n) -> n
  get-alpha: (n) -> 0.7 * ease.sin 1 - n
