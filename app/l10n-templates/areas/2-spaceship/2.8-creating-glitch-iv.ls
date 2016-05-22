eak.register-level-script '2-spaceship/2.8-creating-glitch-iv.html' do
  tutorial: (t) ->
    dom = React.DOM
    t.set \audio-root '/audio/2.5-2.8'
    t.set \tutor 'ada'
    @area-view.area.ext.glitch-first-step t

    t.step \2-tricky, \09-tricky-t2, keep-say: true, ->
      t.say [
        'This one\'s tricky. '
        t.show-at 1.5, [
          'The '
          dom.code null, '/'
          ' in the closing tag isn\'t in the right place.'
        ]
      ]

    t.step \3-before, \10-before-t1, keep-say: true, ->
      t.say [
        'The '
        dom.code null, '/'
        ' in a closing tag should be before the '
        dom.code null, 'p'
        ', not after.'
      ]
