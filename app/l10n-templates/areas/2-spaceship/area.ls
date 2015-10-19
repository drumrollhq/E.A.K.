eak.register-area-script '2-spaceship' do
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

