require! {
  'game/actors/Actor'
  'lib/channels'
}

module.exports = class Activatable extends Actor
  @from-el = -> ...

  physics: data:
    dynamic: false
    sensor: true

  initialize: (options) ->
    super options
    @render!
    @down-sub = channels.parse 'key-down: j, s, down' .subscribe @activate.bind this
    @down-sub.pause!
    @listen-to this, \contact:start:ENTITY_PLAYER, ~> @down-sub.resume!
    @listen-to this, \contact:end:ENTITY_PLAYER, ~> @down-sub.pause!

  render: ->
    @$el.add-class \activatable

  remove: ->
    @down-sub.unsubscribe!

  activate: -> ...
