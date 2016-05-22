eak.register-area-script '2-spaceship' do
  setup: ->
    glitch-first-step-seen = ~>
      !! @stage-store.get \stage.state.shownGlitchFirstStep

    @ext.glitch-first-step = (t) ~>
      t.step \1-fixed, \01-fixed-t1, skip-if: glitch-first-step-seen, keep-say: true, ~>
        @stage-store.patch-stage-state shown-glitch-first-step: true
        t.say [
          'Right! Lets get these engines fixed. '
          t.show-at 3, 'Remember the code you just wrote? '
          t.show-at 5, 'Use that pattern to fix the error here.'
        ]

  before-start: ->
    if @stage-store.get \stage.state.shownIntro then return Promise.resolve!
    eak.play-cutscene '/cutscenes/2-spaceship-zoom'

  after-start: ->
    if @stage-store.get \stage.state.shownIntro then return Promise.resolve!
    eak.start-conversation "/#{EAK_LANG}/areas/2-spaceship/tarquin-greeting" .then ~>
      @stage-store.patch-stage-state shown-intro: true

  stop-edit: ->
    no-errors = @view.levels
      |> filter ( .has-errors )
      |> empty

    if no-errors and not @stage-store.get \stage.state.shownEngines
      eak.play-cutscene '/cutscenes/2-spaceship-engines'
        .then ~> @stage-store.patch-stage-state shown-engines: true

