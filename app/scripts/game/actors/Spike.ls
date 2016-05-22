require! {
  'game/actors/Actor'
  'lib/channels'
}

module.exports = class Spike extends Actor
  @from-el = ($el, [style, direction = \up], offset, save-level) ->
    new Spike {
      style: style
      direction: direction
      el: $el
      offset: offset
      store: save-level
    }

  physics: data:
    dynamic: false
    sensor: true

  mapper-ignore: false

  initialize: (options) ->
    super options
    this <<< options.{style, direction}
    @render!
    @listen-to this, \contact:start:ENTITY_PLAYER, @kill

  render: ->
    @$el.add-class "spike #{@style}-#{@direction}"

  kill: (player) ->
    channels.death.publish cause: \spike
    player.fall-to-death!
