eak.register-level-script '2-spaceship/2.5-creating-glitch-i.html' do
  tutorial: (t) ->
    dom = React.DOM
    t.set \audio-root '/audio/2.5-2.8'
    t.set \tutor 'ada'
    @area-view.area.ext.glitch-first-step t

    t.step \2-any, \03-any-t3, keep-say: true, ->
      t.say [
        'This element needs an opening and a closing tag. '
        t.show-at 3, 'Does it look like everything is here?'
      ]

    t.step \3-closing, \04-closing-t3, keep-say: true, ->
      t.say [
        'You need to add a closing '
        dom.code null, '</p>'
        ' tag to this element.'
      ]
