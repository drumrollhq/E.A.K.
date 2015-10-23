require! {
  'assets'
  'audio/play-conversation-line'
}

dom = React.DOM
{CSSTransitionGroup} = React.addons

module.exports = CharacterMessages = React.create-class do
  display-name: \CharacterMessages

  statics:
    OverwrittenError: class OverwrittenError extends Error
    default-button-label: 'OK'

  get-initial-state: -> {
    active: false
    from: null
    content: null
    button-label: null
  }

  activate: (message) -> new Promise (resolve, reject) ~>
    @_playing-promise.cancel! if @_playing-promise?.cancel?
    @deactivate (new CharacterMessages.OverwrittenError "Overwritten by #{message.from}"), false
    @set-state do
      active: true
      from: message.from
      content: message.content
      button-label: message.button-label or CharacterMessages.default-button-label

    @_resolve = resolve
    @_reject = reject

    if message.track
      @_playing-promise = Promise.delay 300ms
        .cancellable!
        .then -> play-conversation-line message.track
        .then -> Promise.delay if message.timeout? then message.timeout else 3000ms
        .then ~> @deactivate! if message.timeout isnt 0

  deactivate: (success = true, clear = true) ->
    if @_resolve
      if success instanceof Error then @_reject success else @_resolve success
      @_resolve = @_reject = null

    if clear
      @set-state do
        active: false
        from: null
        content: null
        button-label: CharacterMessages.default-button-label

    else
      @set-state active: false

  render: ->
    React.create-element CSSTransitionGroup, {transition-name: \character-message},
      unless @state.from
        null
      else
        dom.div key: @state.from, class-name: (cx \character-message, inactive: not @state.active),
          dom.img class-name: \character-message-character, src: (assets.load-asset "/content/common/character-messages/#{@state.from}.png", \url)
          dom.div class-name: \character-message-speech-bubble, on-click: (~> @set-state active: not @state.active),
            @state.content
            dom.button class-name: '\character-message-dismiss btn btn-small', on-click: @deactivate,
              @state.button-label
