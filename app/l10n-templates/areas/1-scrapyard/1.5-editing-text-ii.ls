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

  tutorial: (t) ->
    dom = React.DOM

    t.set \audio-root, '/audio/1.5'
    t.set \tutor, 'oracle' # asset missing (ada)
    t.setup ->
      t.lock-code! # make read only
      t.unlock-code 'p::inner' # make inside of tags not read only, change content of tags, not structure

    t.step \1-editor, \03-editor, keep-say: true, ->
      t.say [
        'First off, this is the editor. '
        t.show-at 1.8, 'You can press "Save" when you\'re done '
        t.show-at 3.3, ' or "Cancel" to return to the game.'
      ], left: '7.2vw', top: '22vh'

      t.at 2.0 ->
        t.highlight-dom '#editor .save'

      t.at 3.5 ->
        t.clear-highlight!
        t.highlight-dom '#editor .cancel'

      t.at 5.5 ->
        t.say [
          '"Cancel" will get rid of your changes though'
          t.show-at 7.5, ', so watch out!'
        ], left: '51vw', top: '2vh'
         .await-event \start-typing
         .then -> Promise.race [
           t.wait 3s
         ]

      t.at 9 ->
        t.clear-highlight!

    t.step \2-editor, \03a-editor, keep-say: true, ->
      t.clear-highlight!
      t.say [
        'One of the best ways to solve these things'
        t.show-at 1.5, ' is just to experiment and try things out. '
      ], left: '51vw', top: '10vh'

      t.at 4.5 ->
        t.say [
          'It doesn\'t matter if you mess things up'
          t.show-at 6.5, ' - just press "Reset" to put the code back to how it started.'
        ], left: '51vw', top: '10vh'
        t.await-event \reset

      t.at 7.0 ->
        t.highlight-dom '#editor .reset'

      t.at 10.5 ->
        t.clear-highlight!

    t.step \3-help, \04-help, keep-say: true, ->
      t.say [
        'If you need any help, click this button here.'
         t.show-at 2, ' Try pressing it now.'
      ], left: '7.2vw', top: '22vh'
      t.at 1.5 ->
        t.highlight-dom '#editor .help'
        t.await-event \help

      t.at 4 ->
        t.clear-highlight!

    t.step \4-too-long, \05-too-long, keep-say: true, ->
      t .highlight-level 'p'
        .say [
          'Ugh, these ledges are too long.'
          t.show-at 2, ' Try deleting some of the black text to create a safe path into the cave.'
        ], left: '51vw', top: '12vh'

    t.step \5-click, \06-click, keep-say: true, ->
      t .say 'Click on the black writing here.', left: '8.2vw', top: '22vh'
      t .highlight-code 'p::inner' .await-select 'p::inner'

    t.step \6-delete, \07-delete, keep-say: true, ~>
      t .say 'Now, delete some of the text to make the ledge shorter.', left: '8.2vw', top: '22vh'
        .await-event \start-typing
        .then ~> Promise.race [
          t.await-event \stop-typing
        ]

    t.step \7-save, \08-save, keep-say: true, ~>
      t .say 'Awesome! Press "Save" and let\'s get going.', left: '8.2vw', top: '22vh'
