require! 'lib/channels'

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
    (new Promise (resolve) -> channels.parse 'game-commands:start-edit' .once resolve)
      .then ->
        overlay.drop-out!

eak.register-level-script '2-spaceship/2.2-creating-elements-i.html' do
  activate: ->
    prompt-edit this

  tutorial: (t) ->
    dom = React.DOM
    t.set \audio-root '/audio/2.2'
    t.set \tutor 'ada'

    t.step \step-1-id, \05-follow-t1, ->
      t.say [
        'You need to create two more boxes to get to the bottom.'
         t.show-at 2.0, ' Follow the same pattern as the existing boxes to make a new one.'
      ], left: '7.2vw', top: '25vh'
      t.highlight-code 'p'
      t.await-event \start-typing

    t.step \step-2-id, \06-start-t1, ->
      t.say [
        'Start with a <p>'
        t.show-at 2.5, '. This means "start a box".'
      ], left: '7.2vw', top: '35vh'
      t.await-event \start-typing
      .then ~> Promise.race [
        t.await-event \stop-typing
      ]

    t.step \step-3-id, \08-contents-t2, ->
      t.say [
        'Next, write the contents of your box.'
      ], left: '7.2vw', top: '35vh'
      t.await-event \start-typing
      .then ~> Promise.race [
        t.await-event \stop-typing
      ]

    t.step \step-4-id, \09-finish-t2, ->
      t.say [
        'Finish off with </p>'
         t.show-at 2.7, '. This means "I\'ve finished the box"'
      ], left: '7.2vw', top: '35vh'
      t.await-event \start-typing

    t.step \step-5-id, \11-pointy-t1, ->
      t.say [
        'To type those weird pointy brackets, hold down the shift key, then press the key with the pointy bracket you want'
      ], left: '7.2vw', top: '35vh'
      t.await-event \start-typing
      .then ~> Promise.race [
        t.await-event \stop-typing
      ]

    t.step \step-6-id, \12-looking-good-t1, ->
      t.say [
        'Looking good!'
      ], left: '7.2vw', top: '35vh'