eak.register-level-script '2-spaceship/2.2-creating-elements-i.html' do
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