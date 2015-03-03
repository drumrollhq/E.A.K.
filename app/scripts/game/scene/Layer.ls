module.exports = class Layer extends Backbone.View
  class-name: -> "layer #{@layer-type!}"
  layer-type: -> dasherize(Object.get-prototype-of this .constructor.display-name)

  initialize: ({@width, @height}) ->
    @_display-objects = []
    @_activated = null

  add: (display-object, {x = 0, y = 0}) ->
    obj = @_display-objects[*] = {object: display-object, x: x, y: y}
    @trigger \add obj

  object-at: ({x, y}) ->
    for object in @_display-objects when typeof object.contains is \function
      if object.contains x, y then return object

    return null

  activate: (display-object) ->
    unless display-object in @_display-objects then @add display-object

    if @_activated? then @_activated.deactivate!
    display-object.activate!
    @_activated = display-object

  deactivate: ->
    if @_activated? then @_activated.deactivate!
    @_activated = null

  set-viewport: (x, y, width, height) -> ...
