require! {
  'game/scene/Layer'
}

module.exports = class WebglLayer extends Layer
  tag-name: \canvas
  initialize: (options) ->
    super options
    @_resolution = window.device-pixel-ratio or 1
    @_viewport-width = 300
    @_viewport-height = 300
    @_stage = new PIXI.Container!
    @stage = new PIXI.Container!
    @_stage.add-child @stage
    @_layers = [new PIXI.Container! for i to 6]
    for layer in @_layers => @stage.add-child layer
    @_needs-viewport = []
    @renderer = new PIXI.WebGLRenderer @_viewport-width, @_viewport-height, {
      view: @el
      transparent: true
      resolution: @_resolution
    }

  add: (object, at = 3, needs-viewport = false) ->
    super object, x: 0, y: 0
    @_layers[at].add-child object
    if needs-viewport then @_needs-viewport[*] = object

  render: ->
    for obj in @_needs-viewport => obj.set-viewport @left, @top, @right, @bottom
    @renderer.render @_stage

  set-viewport: (x, y, width, height) ->
    if @_viewport-width isnt width or @_viewport-height isnt height
      @_update-viewport-size width, height

    @ <<< left: x, top: y, right: x + width, bottom: y + height
    @stage.position.x = -x
    @stage.position.y = -y

    @render!

  _update-viewport-size: (width, height) ->
    @_viewport-width = width
    @_viewport-height = height
    @renderer.resize width, height
    @renderer.view.style <<< {width: "#{width}px", height: "#{height}px"}
    @stage.filter-area = new PIXI.Rectangle 0, 0, width, height
