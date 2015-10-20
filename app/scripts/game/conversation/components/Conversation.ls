require! {
  'assets'
  'game/conversation/components/Line'
  'game/conversation/components/Speaker'
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

  on-line-first-play-completed: ->
    @get-model!.trigger \line-first-play-completed

  on-line-play: (line) ->
    @_playing = line

  on-line-play-completed: ->
    @_playing = null

  skip: ->
    if @_playing then @_playing.stop-playing!

  component-did-update: ->
    @update-scroll!

  component-will-unmount: ->
    clear-timeout @scroll-timer

  render: ->
    [player, player-expression] = (@state.model.view.player or 'arca neutral').split ' '
    [speaker, speaker-expression] = (@state.model.view.speaker or '').split ' '

    player-img = @state.model.view.characters?[player]?.image or player
    speaker-img = @state.model.view.characters?[speaker]?.image or speaker
    player-background = @state.model.view.characters?[player]?.background or void
    speaker-background = @state.model.view.characters?[speaker]?.background or void

    background = assets.load-asset @state.model.view.background, \url

    dom.div class-name: \conversation, style: {background-image: "url('#{background}')"},
      dom.div class-name: \conversation-lines, style: {background-color: @state.model.view.background-color},
        React.create-element CSSTransitionGroup, {
          component: \ul
          class-name: \clearfix
          ref: \lines
          transition-name: \conversation-line
        }, for line in @state.model.lines
            speaker = @state.model.view.characters?[line.speaker.to-lower-case!]?.name or line.speaker
            React.create-element Line, {
              key: line.id
              from-player: line.from-player
              speaker: speaker
              line: line.line
              audio-root: line.audio-root
              track: line.track
              options: line.options
              on-play: @on-line-play
              on-first-play-completed: @on-line-first-play-completed
              on-play-completed: @on-line-play-completed
            }

        dom.div class-name: (cx \conversation-choice \active),
          if @state.choice-active
            dom.div key: \choices,
              dom.h4 null, "#{@state.{}choice.{}name.name or 'Arca'}:"
              dom.ul null,
                for let choice, i in @state.{}choice.[]choices
                  dom.li class-name: \choice, key: i,
                    dom.a on-click: (~> @choose i), choice
          else
            dom.div key: \skip,
              dom.ul null,
                dom.li class-name: \choice,
                  dom.a on-click: @skip, 'Skip'

      React.create-element Speaker, character: speaker-img, expression: speaker-expression, background: speaker-background, position: \left
      React.create-element Speaker, character: player-img, expression: player-expression, background: player-background, position: \right
}
