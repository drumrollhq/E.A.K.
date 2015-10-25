require! {
  'lib/channels'
  'lib/timer'
}

creepy-tree-hands = do
  from: \ada
  content: 'Yep, try to avoid the creepy tree hands. They really don\'t get personal space...'
  track: '/audio/1.5/01-avoid'

eak.register-level-script '1-scrapyard/1.5-editing-text-ii.html' do
  initialize: ->
    @current-message = Promise.resolve!
    @message = (msg) ~>
      @current-message.then ~> @current-message = eak.character-messages.activate msg

    (@edit-prompt-timer = timer 10000).then ~>
      @message msg

  activate: ->
    @edit-prompt-timer.start!
    @spike-sub = channels.parse \death:spike .subscribe ~>
      unless @level-store.get \state.shownSpikeHint
        @level-store.patch-state shown-spike-hint: true
        @message creepy-tree-hands

  deactivate: ->
    @spike-sub.unsubscribe!
    @edit-prompt-timer.stop!
