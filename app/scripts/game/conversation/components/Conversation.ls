require! {
  'assets'
}

dom = React.DOM
{CSSTransitionGroup} = React.addons

module.exports = React.create-class {
  mixins: [Backbone.React.Component.mixin]
  display-name: \Conversation

  get-initial-state: -> {
    choice-active: false
  }

  choice: (name, choices, cb) ->
    console.log arguments
    @set-state choice: {name, choices, cb}, choice-active: true

  choose: (idx) ->
    cb = @state.choice.cb
    @set-state choice-active: false
    cb idx

  update-scroll: ->
    clear-timeout @scroll-timer if @scroll-timer?
    @scroll-timer = set-timeout do
      ~>
        lines = @refs.lines.get-DOM-node!
        $lines = $ lines
        $lines.stop!.animate scroll-top: (lines.scroll-height - $lines.height!), 200
      50

  component-did-update: ->
    @update-scroll!

  render: ->
    player = @state.model.view.player or 'arca'
    player-expression = @state.model.view.player or 'neutral'
    speaker = @state.model.view.speaker
    speaker-expression = @state.model.view.speaker-expression or 'neutral'

    player-img = assets.load-asset "/entities/#{player}-conversation/#{player-expression}.png", \url
    if speaker
      speaker-img = assets.load-asset "/entities/#{speaker}-conversation/#{speaker-expression}.png", \url

    dom.div class-name: \conversation,
      dom.div class-name: \conversation-lines,
        React.create-element CSSTransitionGroup, {
          component: \ul
          class-name: \clearfix
          ref: \lines
          transition-name: \conversation-line
        }, for line in @state.model.lines
            dom.li key: line.id, class-name: (cx \conversation-line, \conversation-line-player : line.from-player),
              dom.div class-name: \conversation-line-speaker, line.speaker
              dom.div class-name: \conversation-line-line, line.line

        dom.div class-name: (cx \conversation-choice active: @state.choice-active),
          dom.h4 null, @state.{}choice.name + ':'
          dom.ul null,
            for let choice, i in @state.{}choice.[]choices
              dom.li class-name: \choice, key: i,
                dom.a on-click: (~> @choose i), choice

      React.create-element CSSTransitionGroup, {
        transition-name: \conversation-speaker
        class-name: 'conversation-speaker conversation-speaker-left'
        component: \div
      }, dom.img src: speaker-img, key: speaker-img

      React.create-element CSSTransitionGroup, {
        transition-name: \conversation-speaker
        class-name: 'conversation-speaker conversation-speaker-right'
        component: \div
      }, dom.img src: player-img, key: player-img
}
