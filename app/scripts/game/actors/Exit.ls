require! {
  'game/actors/Actor'
  'lib/channels'
}

module.exports = class Exit extends Actor
  @from-el = ($el, [href], offset, save-level) ->
    new Exit {
      href: href
      el: $el
      offset: offset
      store: save-level
    }

  physics: data:
    dynamic: false

  mapper-ignore: false

  initialize: (options) ->
    super options
    @href = options.href
    @listen-to this, \contact:start:ENTITY_PLAYER, @go

  go: ->
    channels.stage.publish url: @href
