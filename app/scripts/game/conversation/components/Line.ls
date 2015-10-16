require! {
  'audio/play-conversation-line'
}

dom = React.DOM

module.exports = React.create-class {
  display-name: \Line

  get-initial-state: -> {
    first-play-completed: false
    playing: false
  }

  play-track: ->
    if @props.track and not (not @state.first-play-completed and \skip-first-play in @props.options)
      @set-state playing: true
      @props.on-play this if @props.on-play
      play-conversation-line @props.audio-root, @props.track
        .then @play-completed

    else
      @play-completed!

  play-completed: ->
    unless @state.first-play-completed
      @set-state first-play-completed: true
      @props.on-first-play-completed this if @props.on-first-play-completed

    @set-state playing: false
    @props.on-play-completed this if @props.on-play-completed

  stop-playing: ->
    play-conversation-line.stop!

  toggle-play: ->
    if @state.playing
      @stop-playing!
    else
      @play-track!

  component-did-mount: ->
    @play-track!

  render: ->
    dom.li class-name: (cx \conversation-line, \conversation-line-player : @props.from-player),
      dom.div class-name: \conversation-line-speaker, @props.speaker
      dom.div class-name: \conversation-line-line, @props.line
      if @props.track
        dom.a class-name: (cx \conversation-line-play @state.{playing}), on-click: @toggle-play
}
