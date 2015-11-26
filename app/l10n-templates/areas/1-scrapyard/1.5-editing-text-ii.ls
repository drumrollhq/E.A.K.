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

  tutorial: (tutorial) ->
    [[\tutor 'ada']
    [\lock]

    [\step \1-first
      [\say \1.1-first-off {} 0: 'first off, this is the editor']
      [\say \1.2-save {target: '#editor .save' focus: true}
        0: 'You can press save when you\'re done']
      [\say \1.3-cancel {target: '#editor .cancel'}
        0: 'or \'cancel\' to return to the game - \'cancel\' will get rid of your changes though, so watch out!']]

    [\step \2-experiment
      [\say \2.1-experiment {}
        0: 'One of the best ways to solve these things is to just experiment and try things out']
      [\say \2.2-matter {}
        0: 'It doesn\'t matter if you mess things up - ']
      [\say \2.3-reset {target: '#editor .reset' focus: true}
        0: 'just press \'reset\' to put the code back to how it started.']]

    [\step \3-help
      [\say \3-help {target: '#editor .help', focus: true}
        0: 'If you need any help, click this \'help\' button here. Try pressing it now.']]

    [\target \press-help 'Ask for help' {wait: true}
      -> tutorial.help-requests ?= 1]

    [\help
      [\step \4-too-long
        [\unlock 'p::inner']
        [\say \4-too-long {}
          0: 'These ledges are too long. Try deleting some of the black text to create a safe path into the cave.']]
      [\target \delete-text 'Make the ledges short enough to get into the cave.'
        ({$}) -> 'p:nth-of-type(1)' .width! < 500]]

    [\optional
      [\after 10_000ms {without-event: 'change'}
        [\highlight-dom '#editor .help' {focus: true timeout: 3_000ms}]]]

    [\help
      [\step \5-like-before
        [\say \5-like-before {target-code: 'p:nth-of-type(1):inner' async: true interruptible: true}
          0: 'Just like before, click on the black writing here']
        [\await-select 'p:inner']]
      [\step \6-delete
        [\say \6-delete 'Now, delete some of the text to make the ledge shorter']]]]

