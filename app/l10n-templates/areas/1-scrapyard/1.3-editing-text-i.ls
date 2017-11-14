require! {
  'lib/channels'
  'game/event-loop'
  'game/actors/Actor'
  'game/actors/mixins/Conditional'
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

function update-class level
  currently-showing = level.$el.has-class \ledge-crumbled
  should-show = level.stage-store.get \stage.state.ledgeCrumbled

  if (not currently-showing) and should-show
    level.$el.add-class \ledge-crumbled
    level.area-view.area.refresh!
  else if currently-showing and (not should-show)
    level.$el.remove-class \ledge-crumbled
    level.area-view.area.refresh!

eak.register-level-script '1-scrapyard/1.3-editing-text-i.html' do
  initialize: ->
    @tut-in-progress = false
    @ledge-crumble = ~>
      unless @tut-in-progress or @stage-store.get \stage.state.doneEditTutorial
        @tut-in-progress = true
        eak._stage.view.player.fall-to-death!
        eak.play-cutscene '/cutscenes/1-scrapyard-fall'
          .then ~> eak.start-conversation "/#{EAK_LANG}/areas/1-scrapyard/before-arca-codes"
          .then ~>
            @stage-store.patch-stage-state ledge-crumbled: true
            @done-first-part = true
            prompt-edit this
          .then ~> eak.start-conversation "/#{EAK_LANG}/areas/1-scrapyard/after-arca-codes"
          .then ~> @stage-store.patch-stage-state done-edit-tutorial: true
          .finally ~> @tut-in-progress = false

  activate: ->
    @stage-store.on \change, ~> update-class this
    update-class this

  editable: ->
    # true
    done-tutorial = @stage-store.get \stage.state.doneEditTutorial
    !!(done-tutorial or (@tut-in-progress and @done-first-part))

  tutorial: (t) ->
    dom = React.DOM

    t.set \audio-root, '/audio/1.3'
    t.set \tutor, 'oracle'
    t.setup ->
      t.lock-code!
      t.unlock-code 'p::inner'

    t.step \1-pantaloons, \28-voluptous-vegetables, keep-say: true, ~>
      t.say [
        'Voluptuous vegetables! '
        t.show-at 2, 'You actually did it! '
        t.show-at 3.5, 'Perhaps you could learn to code...'
      ]

    t.step \2-writing, \29-your-surroundings, keep-say: true, ~>
      t .highlight-code 'p'
        .say [
          'The writing on the left is the code for your surroundings '
          t.show-at 3.5, '- shown on the right.'
        ], top: '130px'
      t.at 3 ~>
        t.set 'msg.options' left: '53vw', top: '30vh'
        t.clear-highlight!.highlight-level 'p'

    t.step \3-change, \30-changing-code, keep-say: true, ~>
      t.say [
        'Let\'s try changing the code. '
        t.show-at 2 'Click the black writing here.'
      ], left: '53vw', top: '30vh'
      t.at 2 ~>
        t.set 'msg.options' left: '100px', top: '130px'
        t.highlight-code 'p::inner' .await-select 'p::inner'

    t.step \4-name, \31-type-name, keep-say: true, ~>
      t .say 'Now, type your name', left: '100px', top: '130px'
        .await-event \start-typing
        .then ~> Promise.race [
          t.wait 2s
          t.await-event \stop-typing
        ]

    t.step \5-surroundings, \32-changes-surroundings, keep-say: true, ~>
      t.say 'See how changing the code changes your surroundings?', left: '100px', top: '130px'
      t.at 3 ~>
        t .say [
          'Keep typing to make the ledge long enough for you to reach the other side. '
          t.show-at 7, 'You can write anything you want!'
        ]

    t.target \long-enough,
      desc: 'Make the ledge long enough to reach the other side.',
      condition: ({$}) ->
        ($ 'p:nth-of-type(1)' .width!) + ($ 'p:nth-of-type(2)' .width!) > 450
      finish: ~>
        t.once \wait-before-saving ~>
          t.step \6-smashing, \33-smashing ~>
            t .say 'Smashing work my little vegetable soup!'
              .at 3 ~> t.say 'You picked that up faster than a squirrel on a scooter'
              .at \end ~> t.save!

class LedgeDetector extends Actor
  @from-el = ($el, _, offset, store, area-view, area-level) ->
    new LedgeDetector {
      el: $el
      offset,
      store,
      area-view,
      area-level,
    }

  physics: data:
    dynamic: false

  mapper-ignore: false
  sensor: true

  initialize: (options) ->
    super options

    @listen-to-once this, \contact:start:ENTITY_PLAYER, ->
      @area-level?.ledge-crumble?!

eak.register-actor LedgeDetector
