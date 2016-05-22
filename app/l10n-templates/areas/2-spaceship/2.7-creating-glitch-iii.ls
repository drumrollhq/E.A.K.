eak.register-level-script '2-spaceship/2.7-creating-glitch-iii.html' do
  tutorial: (t) ->
    dom = React.DOM
    t.set \audio-root '/audio/2.5-2.8'
    t.set \tutor 'ada'
    @area-view.area.ext.glitch-first-step t

    t.step \2-closing, \07-2-closing-t1, keep-say: true, ->
      t.say 'There\'s two closing tags!'

    t.step \3-supposed, \08-supposed-t1, keep-say: true, ->
      t.say [
        'The first tag has a '
        dom.code null, '/'
        ' in it - like a closing tag. '
        t.show-at 3, 'But it\'s supposed to be an opening tag.'
      ]
