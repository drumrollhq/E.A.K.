require! {
  'game/actors/Actor'
  'game/actors/mixins/Activatable'
  'game/actors/mixins/Conditional'
  'lib/channels'
}

module.exports = mixin Activatable, Conditional, class Portal extends Actor
  @from-el = ($el, [href], offset, store, area-view) ->
    new Portal {
      href: href
      el: $el
      offset: offset
      store: store,
      area-view: area-view
    }

  mapper-ignore: false

  initialize: (options) ->
    super options
    @href = options.href

  activate: ->
    # no idea what causes the game to restart sometimes when activating app portals lol
    if @href.match /app/
      hash = @href.replace /^eak:\/\//, '#/'
      window.location.hash = hash
    else
      channels.stage.publish url: @href

  turn-on: ->
    unless @activatable-listening then @start-activatable-listening!
    @$el.remove-class \disabled
      .add-class \activatable

  turn-off: ->
    if @activatable-listening then @stop-activatable-listening!
    @$el.add-class \disabled
      .remove-class \activatable

