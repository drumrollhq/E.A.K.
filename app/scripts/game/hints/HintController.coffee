mediator = require "game/mediator"

hintTypes =
  pointer: require "game/hints/Pointer"
  alert: require "game/hints/AlertPointer"

idCounter = 1

timedEvent = (e, t) ->
  setTimeout ->
    mediator.trigger e
  , t * 1000

module.exports = class HintController extends Backbone.Model
  defaults:
    hints: []

  hintDefaults:
    type: "alert"
    target: ".player"
    content: "You forgot to add content to your hint!"
    enter: "time:1"
    exit: "time:4"
    enterDelay: 0
    exitDelay: 0
    side: false

  initialize: ->
    @hints = @get "hints"

    @setup hint for hint in @hints

  setup: (hint) ->
    idCounter += 1

    HintController::hintDefaults.name = idCounter

    hint = _.defaults hint, HintController::hintDefaults

    hintView = new hintTypes[hint.type] hint

    hint.view = hintView

    enter = hint.enter
    if (enter.indexOf "time:") is 0
      time = parseInt (enter.split "time:")[1]
      enter = "HintEnter#{idCounter}"
      timedEvent enter, time

    @listenToOnce mediator, enter, =>
      setTimeout ->
        hintView.render()
        mediator.trigger "hint-#{hint.name}:enter"
      , hint.enterDelay * 1000

      exit = hint.exit
      if (exit.indexOf "time:") is 0
        time = parseInt (exit.split "time:")[1]
        exit = "HintExit#{idCounter}"
        timedEvent exit, time

      @listenToOnce mediator, exit, ->
        setTimeout ->
          hintView.remove()
          mediator.trigger "hint-#{hint.name}:exit"
        , hint.exitDelay * 1000

  destroy: =>
    hint.view.remove() for hint in @hints
