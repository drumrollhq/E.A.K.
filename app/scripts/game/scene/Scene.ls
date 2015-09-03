module.exports = class Scene extends Backbone.View
  class-name: \scene

  (size, camera, options = {}) ->
    super {size, camera, options}

  initialize: ({@size, @camera, @options}) ->
    @_layers = []
    if @options.viewport
      @set-viewport-size @options.viewport.width, @options.viewport.height

  remove: ({include-layers = false} = {}) ->
    if include-layers
      for layer in @_layers => layer.remove!

    super!

  step: ->
    @set-viewport @camera.offset-x, @camera.offset-y

  add-layer: (layer) ->
    @_layers[*] = layer
    @$el.append layer.el

  add-layers: (...layers) ->
    for layer in layers => @add-layer layer

  set-viewport-size: (width, height) ->
    @viewport-width = width
    @viewport-height = height
    @camera.set-viewport width, height
    @$el.css {width, height}

  set-viewport: (x, y, width = @viewport-width, height = @viewport-height) ->
    if width isnt @viewport-width and @height isnt @viewport-height
      @set-viewport-size width, height

    for layer in @_layers
      layer.set-viewport x, y, width, height, @camera.zoom

  contains: (x, y, pad = 0) ->
    -pad < x < @size.width + pad and -pad < y < @size.height + pad

  render: ->
    for layer in @_layers when layer.render? => layer.render!
