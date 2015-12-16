require! {
  'lib/channels'
  'game/event-loop'
}

function create-edit-prompt-overlay
  $ '<div></div>'
    .html 'Click \'Edit\' in the top left corner, or press the <kbd>E</kbd> key to change the code of this level'
    .css do
      display: \block
      position: \absolute
      top: \50%
      left: 0
      width: \60%
      padding: '3% 10%'
      margin-top: -150px
      margin-left: \20%
      background: 'rgba(255, 255, 255, 0.9)'
      border-radius: 5px
      box-shadow: '0 0 60px rgba(0, 0, 0, 0.5)'
      font-size: \30px
      font-weight: \300
      line-height: \1.5em
      text-align: \center
      z-index: \1000
    .drop-in document.body

function is-solved level
  width = level
    .$ \p
    .to-array!
    .reduce ((total, el) -> $ el .width! + total), 0

  width > 450

function prompt-edit level
  overlay = create-edit-prompt-overlay!
  eak.view.player.freeze!
  (new Promise (resolve) -> channels.parse 'game-commands:start-edit' .once resolve)
    .then ->
      overlay.drop-out!
      new Promise (resolve) -> channels.parse 'game-commands:stop-edit' .once resolve
    .then ->
      if is-solved level then eak.view.player.unfreeze!
      else prompt-edit level

eak.register-level-script '1-scrapyard/1.3-editing-text-i.html' do
  initialize: ->
    @tut-in-progress = false
    @death-sub = channels.parse 'death:fall-out-of-world' .subscribe ~>
      unless @tut-in-progress or @stage-store.get \stage.state.doneEditTutorial
        @tut-in-progress = true
        eak.play-cutscene '/cutscenes/1-scrapyard-fall'
          .then ~> eak.start-conversation "/#{EAK_LANG}/areas/1-scrapyard/before-arca-codes"
          .then ~>
            @done-first-part = true
            prompt-edit this
          .then ~> eak.start-conversation "/#{EAK_LANG}/areas/1-scrapyard/after-arca-codes"
          .then ~> @stage-store.patch-stage-state done-edit-tutorial: true
          .finally ~> @tut-in-progress = false

    @death-sub.pause!

  activate: ->
    @death-sub.resume!

  deactivate: ->
    @death-sub.pause!

  cleanup: ->
    @death-sub.unsubscribe!

  editable: ->
    true
    # done-tutorial = @stage-store.get \stage.state.doneEditTutorial
    # !!(done-tutorial or (@tut-in-progress and @done-first-part))

  tutorial: (t) ->
    t .set \audio-root, '/audio/1.3'
      .set \tutor, 'lao'
      .setup ->
        t.lock-code!
        t.unlock-code 'p::inner'

      .step \1-pantaloons, \28-voluptous-vegetables, ~>
        t .at 0 ~> t.say 'Voluptuous vegetables! You actually did it!'
          .at 3 ~> t.say 'Perhaps you could learn to code...'

      .step \2-writing, \29-your-surroundings, ~>
        t .highlight-code 'p'
          .say 'The writing on the left is the code for your surroundings -'
          .at 3 ~>
            t .say 'shown on the right'
              .clear-highlight!
              .highlight-level 'p'

      .step \3-change, \30-changing-code, ~>
        t .say 'Let\'s try changing the code'
          .at 2.2 ~>
            t .say target-code: 'p::inner', 'Click the black writing here.'
              .highlight-code 'p::inner'
              .await-select 'p::inner'

      .step \4-name, \31-type-name, ~>
        t .say 'Now, type your name'
          .await-event \start-typing
          .then ~> Promise.delay 4_000ms

      .step \5-surroundings, \32-changes-surroundings, ~>
        t .say 'See how changing the code changes your surroundings?'
          .at 3 ~> t.say 'Keep typing to make the ledge long enough for you to reach the other side.'
          .at 6 ~> t.say 'You can write anything you want!'

      .target \long-enough,
        desc: 'Make the ledge long enough to reach the other side.',
        condition: ({$}) ->
          ($ 'p:nth-of-type(1)' .width!) + ($ 'p:nth-of-type(2)' .width!) > 450
        finish: ~>
          t.once \wait-before-saving ~>
            t.step \6-smashing, \33-smashing ~>
              t .say 'Smashing work my little vegetable soup!'
                .at 3 ~> t.say 'You picked that up faster than a squirrel on a scooter'
                .at \end ~> t.save!
    # [[\set \audio-root '/audio/1.3']
    # [\tutor 'lao']
    # [\lock]
    # [\unlock 'p:inner']
    # [\wait 1_000ms]
    #
    # [\step \1-pantaloons
    #   [\say \28-voluptous-vegetables {}
    #     0: 'Voluptuos vegetables! You actually did it!'
    #     3: 'Perhaps you could learn some code...']]
    #
    # [\step \2-writing
    #   [\highlight-code 'p']
    #   [\say \29-your-surroundings {async: true}
    #     0: 'The writing on the left is the code for your surroundings -'
    #     3: 'shown on the right']
    #   [\wait 3_000ms]
    #   [\clear-highlight]
    #   [\highlight-level 'p']]
    #
    # [\step \3-change
    #   [\say \30-changing-code {async: true}
    #     0: 'Let\'s try changing the code.'
    #     1: target-code: 'p:inner', content: 'Click the black writing here.']
    #   [\wait 2_200ms]
    #   [\highlight-code 'p:inner']
    #   [\await-select 'p:inner']]
    #
    # [\step \4-name
    #   [\say \31-type-name {async: true} 0: 'Now, type your name']
    #   [\await-event \start-typing]
    #   [\wait 4_000ms]]
    #
    # [\step \5-surroundings
    #   [\say \32-changes-surroundings {}
    #     0: 'See how changing the code changes your surroundings?'
    #     3: 'Keep typing to make the ledge long enough for you to reach the other side.'
    #     6: 'You can write anything you want!']]
    #
    # [\target \long-enough {block: true}
    #   ({$}) -> ($ 'p:nth-of-type(1)' .width!) + ($ 'p:nth-of-type(2)' .width!) > 450]
    #
    # [\once \wait-before-saving [\await-event 'stop-typing']]
    #
    # [\step \6-smashing
    #   [\say \33-smashing {}
    #     0: 'Smashing work my little vegetable soup!'
    #     3: 'You picked that up faster than a squirrel on a scooter']
    #   [\save]]]
