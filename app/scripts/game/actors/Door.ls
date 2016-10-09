require! {
  'game/actors/Actor'
  'game/actors/mixins/Conditional'
  'lib/channels'
}

module.exports = class Door extends Conditional(Actor)
  @from-el = ($el, _, offset, store, area-view) ->
    options = do
      el: $el
      offset: offset
      store: store
      area-view: area-view

    new Door options

  physics: data:
    dynamic: false

  mapper-ignore: false

  initialize: (options) ->
    super options

  turn-on: -> @open!
  turn-off: -> @close!

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
