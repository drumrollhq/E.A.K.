require! {
  'game/actors/Actor'
  'game/actors/mixins/Activatable'
  'lib/channels'
}

module.exports = class ConversationTrigger extends Activatable(Actor)
  @from-el = ($el, [name], offset, save-level) ->
    new ConversationTrigger {
      name: name
      el: $el
      offset: offset
      store: save-level
    }

  mapper-ignore: false

  initialize: (options) ->
    super options
    @name = options.name

  activate: ->
    channels.conversation.publish @{name}
