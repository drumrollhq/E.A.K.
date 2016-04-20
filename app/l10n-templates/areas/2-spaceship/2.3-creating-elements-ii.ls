eak.register-level-script '2-spaceship/2.3-creating-elements-ii.html' do
  tutorial: (t) ->
    dom = React.DOM
    t.set \audio-root '/audio/2.3'
    t.set \tutor 'ada'

    t.step \step-1-id, \10-like-before-t1, ->
      t.highlight-level 'div.ledge'
      t.say [
        'You need another box like before '
        t.show-at 1.5, ' - so create a <p> element by following the pattern from last time.'
      ], left: '7.2vw', top: '25vh'
      t.await-event \start-typing
      .then ~> Promise.race [
        t.await-event \stop-typing
      ]

    t.step \step-2-id, \11-remember-t1, ->
      t.say [
        'If you can\'t remember how to write the <p> element for the box,'
        t.show-at 2.5, ' go back to the ones you just made and look at the code you wrote there.'
      ], left: '7.2vw', top: '25vh'
      t.await-event \start-typing
      .then ~> Promise.race [
        t.await-event \stop-typing
      ]

    t.step \step-3-id, \12-start-p-t1, ->
      t.say [
        'OK, start with a <p> opening tag.'
        t.show-at 2.5, ' Now, write something - make sure it\'s long enough!'
        t.show-at 6.0, ' Finish off with a <\/p> closing tag.'
      ], left: '7.2vw', top: '30vh'
      t.await-event \start-typing
      .then ~> Promise.race [
        t.await-event \stop-typing
      ]

    t.step \step-4-id, \15-actually-t1, ->
      t.say [
        'You\'re actually getting the hang of this!'
      ], left: '7.2vw', top: '30vh'
