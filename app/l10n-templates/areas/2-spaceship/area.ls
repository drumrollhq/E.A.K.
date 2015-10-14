eak.register-area-script '2-spaceship' do
  before-start: ->
    if @stage-store.get \stage.state.doneIntro then return Promise.resolve!
    eak.play-cutscene '/cutscenes/2-spaceship-zoom'

  after-start: ->
    if @stage-store.get \stage.state.doneIntro then return Promise.resolve!
    eak.start-conversation "/#{EAK_LANG}/areas/2-spaceship/tarquin-greeting" .then ~>
      @stage-store.patch-stage-state done-intro: true

