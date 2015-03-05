require! {
  'game/scene/Layer'
}

module.exports = class WebglLayer extends Layer
  tag-name: \canvas
  initialize: (options) ->
    super options
    @_viewport-width = 300
    @_viewport-height = 300
    @stage = new PIXI.Stage 0xCCCCCC
    @renderer = new PIXI.WebGLRenderer @_viewport-width, @_viewport-height, {
      view: @el
      transparent: true
      resolution: window.device-pixel-ratio or 1
    }

  render: ->
    @renderer.render @stage

  set-viewport: (x, y, width, height) ->
    if @_viewport-width isnt width or @_viewport-height isnt height
      @_update-viewport-size width, height

    @render!

  _update-viewport-size: (width, height) ->
    @_viewport-width = width
    @_viewport-height = height
    @renderer.resize width, height
