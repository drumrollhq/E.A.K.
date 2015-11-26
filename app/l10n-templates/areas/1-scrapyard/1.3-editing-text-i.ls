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

  tutorial: ->
    [[\tutor 'lao']
    [\lock]
    [\unlock 'p:inner']

    [\step \1-pantaloons
      [\say \1-pink-pantaloons
        0: 'Pink pantaloons! You actually did it!'
        3: 'Perhaps you could learn some code...']]

    [\step \2-writing
      [\highlight-code 'p']
      [\say \2-writing {async: true}
        0: 'The writing on the left is the code for your surroundings -'
        3: 'shown on the right']
      [\wait 3_000ms]
      [\clear-highlight]
      [\highlight-level 'p']]

    [\step \3-change
      [\say \3.1-change 'Let\'s try changing the code.']
      [\say \3.2-click {target-code: 'p:inner', async: true, interruptible: true}
        'Click the black writing here.']
      [\highlight-code 'p:inner']
      [\await-select 'p:inner']]

    [\step \4-name
      [\say \4-name {async: true} 'Now, type your name']
      [\await-event 'change']
      [\wait 3_000ms]]

    [\step \5-surroundings
      [\say \5-surroundings
        0: 'See how changing the code changes your surroundings?'
        3: 'Keep typing to make the ledge long enough for you to reach the other side.'
        6: 'You can write anything you want!']]

    [\target \long-enough {block: true}
      ({$}) -> ($ 'p:nth-of-type(1)' .width!) + ($ 'p:nth-of-type(2)' .width!) > 450]

    [\after 5_000ms {without-event: 'change'}
      [\say \6-scooter
        0: 'Smashing work my little vegetable soup!'
        3: 'You picked that up faster than a squirrel on a scooter']
      [\save]]]
