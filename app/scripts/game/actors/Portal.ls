require! {
  'game/actors/Actor'
  'lib/channels'
}

module.exports = class Portal extends Actor
  @from-el = ($el, [href], offset, save-level) ->
    new Portal {
      href: href
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
    @href = options.href
    @down-sub = channels.parse 'key-down: j, s, down' .subscribe @go
    @down-sub.pause!
    @listen-to this, \contact:start:ENTITY_PLAYER, ~> @down-sub.resume!
    @listen-to this, \contact:end:ENTITY_PLAYER, ~> @down-sub.pause!

  go: ~>
    channels.stage.publish url: @href
