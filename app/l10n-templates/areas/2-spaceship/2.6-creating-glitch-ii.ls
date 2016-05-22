eak.register-level-script '2-spaceship/2.6-creating-glitch-ii.html' do
  tutorial: (t) ->
    dom = React.DOM
    t.set \audio-root '/audio/2.5-2.8'
    t.set \tutor 'ada'
    @area-view.area.ext.glitch-first-step t

    t.step \2-not-actually, \05-not-actually-t1, keep-say: true, ->
      t.say 'This element\'s closing tag isn\'t actually a closing tag...'

    t.step \3-slash, \06-slash-t3, keep-say: true, ->
      t.say [
        'The closing tag needs a slash after the opening pointy bracket: '
        dom.code null, '</p>'
      ]
