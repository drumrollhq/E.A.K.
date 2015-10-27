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

  width > 650

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
      unless @tut-in-progress or @stage-store.get 'state.doneEditTutorial'
        @tut-in-progress = true
        eak.play-cutscene '/cutscenes/1-scrapyard-fall'
          .then ~> eak.start-conversation "/#{EAK_LANG}/areas/1-scrapyard/before-arca-codes"
          .then ~>
            @done-first-part = true
            prompt-edit this
          # .then ~> @stage-store.patch-stage-state done-edit-tutorial: true
          .finally ~> @tut-in-progress = false

    @death-sub.pause!

  activate: ->
    @death-sub.resume!

  deactivate: ->
    @death-sub.pause!

  cleanup: ->
    @death-sub.unsubscribe!

  editable: ->
    done-tutorial = @stage-store.get \state.doneEditTutorial
    !!(done-tutorial or (@tut-in-progress and @done-first-part))
