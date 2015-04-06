require! {
  'game/scene/Layer'
}

module.exports = class WebglLayer extends Layer
  tag-name: \canvas
  initialize: (options) ->
    super options
    @_viewport-width = 300
    @_viewport-height = 300
    @_stage = new PIXI.Container!
    @stage = new PIXI.Container!
    @_stage.add-child @stage
    @renderer = new PIXI.WebGLRenderer @_viewport-width, @_viewport-height, {
      view: @el
      transparent: true
      resolution: 1
    }

  add: (object) ->
    super object, x: 0, y: 0
    @stage.add-child object

  render: ->
    @renderer.render @stage

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
    @stage.filter-area = new PIXI.math.Rectangle 0, 0, width, height