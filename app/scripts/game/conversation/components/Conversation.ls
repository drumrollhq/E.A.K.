dom = React.DOM

module.exports = React.create-class {
  mixins: [Backbone.React.Component.mixin]
  display-name: \Conversation

  get-initial-state: -> {
    choice: null
  }

  choice: (name, choices, cb) ->
    console.log arguments
    @set-state choice: {name, choices, cb}

  choose: (idx) ->
    cb = @state.choice.cb
    @set-state choice: null
    cb idx

  render: ->
    dom.div class-name: \conversation,
      dom.pre null,
        dom.code null, JSON.stringify @state, null, 2
      dom.div class-name: (cx \conversation-choice hidden: not @state.choice),
        dom.h4 null, @state.{}choice.name + ':'
        dom.ul null,
          for let choice, i in @state.{}choice.[]choices
            dom.li class-name: \choice, key: i,
              dom.a on-click: (~> @choose i), choice
}
