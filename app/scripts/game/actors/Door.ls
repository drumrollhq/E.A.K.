require! {
  'game/actors/Actor'
  'lib/channels'
}

module.exports = class Door extends Actor
  @from-el = ($el, [type], offset, store, area-view) ->
    options = switch type
    | \condition => condition: ($el.attr \data-door-condition), trigger: $el.attr \data-door-trigger
    | otherwise => throw new TypeError "No such door type as #{type}"

    options <<< {
      el: $el
      type: type
      offset: offset
      store: store
      area-view: area-view
    }

    new Door options

  physics: data:
    dynamic: false

  mapper-ignore: false

  initialize: (options) ->
    super options
    @type = options.type

    switch @type
    case \condition
      @_trigger-sub = channels.parse options.trigger .subscribe @trigger-update
      @_condition = new Function \eak, \store, \areaView, options.condition
      @trigger-update!

  trigger-update: ~>
    res = @_condition window.eak, @store, @area-view
    if res then @open! else @close!

  open: ~>
    if @_open then return
    @_open = true
    @$el.add-class \door-open
    @sensor = true
    @trigger \open

  close: ~>
    unless @_open then return
    @_open = false
    @$el.remove-class \door-open
    @sensor = false
    @trigger \close
