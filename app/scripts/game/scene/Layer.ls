require! {
  'lib/channels'
}

contains-by = (fn, obj, arr) -->
  undefined isnt find-index (-> obj isnt fn it), arr

module.exports = class Layer extends Backbone.View
  class-name: -> "layer #{@layer-type!}"
  layer-type: -> dasherize(Object.get-prototype-of this .constructor.display-name)

  initialize: ({@width, @height}) ->
    @_display-objects = []
    @_activated = null

  add: (display-object, {x = 0, y = 0}) ->
    obj = @_display-objects[*] = {object: display-object, x: x, y: y}
    @trigger \add obj
    if typeof obj.trigger is \function then obj.trigger \add this

  remove: (object) ->
    idx = @_display-objects |> find-index ( .object is object )
    if idx?
      obj = @_display-objects[idx]
      @_display-objects.splice idx, 1
      @trigger \remove, obj
      if typeof obj.trigger is \function then obj.trigger \remove, this

  object-at: ({x, y}) ->
    for {object} in @_display-objects when typeof object.contains is \function
      if object.contains x, y then return object

    return null

  activate: (display-object) ->
    unless contains-by ( .object ), display-object, @_display-objects
      @add display-object

    if @_activated? then @_activated.deactivate!
    display-object.activate!
    @_activated = display-object

  deactivate: ->
    if @_activated? then @_activated.deactivate!
    @_activated = null

  set-viewport: (x, y, width, height) -> ...

  animate: (duration, fn) -> new Promise (resolve, reject) ~>
    start = performance.now!
    anim = ~>
      amt = (performance.now! - start) / duration
      if amt > 1
        amt = 1
        anim-sub.unsubscribe!
        resolve!

      fn amt

    anim-sub = channels.post-frame.subscribe anim
