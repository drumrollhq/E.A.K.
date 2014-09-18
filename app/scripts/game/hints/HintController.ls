require! {
  'channels'
  'game/hints/Alert'
  'game/hints/Pointer'
}

hint-types = pointer: Pointer, alert: Alert

id-counter = 1

module.exports = class HintController extends Backbone.Model
  defaults: hints: []

  hint-defaults:
    type: \alert
    target: \.player
    content: 'You forgot to add content to your hint!'
    enter: \time:1
    exit: \time:4
    enter-delay: 0
    exit-delay: 0
    position: \below

  initialize: ->
    hint-els = @get \hints

    @hints = []

    hint-els.each (i, el) ~>
      $el = $ el
      obj =
        type: ($el.attr 'hint-type') or el.tag-name.to-lower-case!
        target: ($el.attr 'target') or HintController::hint-defaults.target
        name: ($el.attr 'name') or undefined
        content: $el.html! or HintController::hint-defaults.content
        enter: ($el.attr 'enter') or HintController::hint-defaults.enter
        exit: ($el.attr 'exit') or HintController::hint-defaults.exit
        enter-delay: ($el.attr 'enter-delay') or HintController::hint-defaults.enter-delay
        exit-delay: ($el.attr 'exit-delay') or HintController::hint-defaults.exit-delay
        position: ($el.attr 'position') or HintController::hint-defaults.position

      @hints.push obj

    [@setup hint for hint in @hints]

  setup: (hint) ->
    id-counter += 1

    HintController::hint-defaults.name = "hint-#{id-counter}"

    hint = _.defaults hint, HintController::hint-defaults

    view = new hint-types[hint.type] hint

    hint <<< {view}
    {enter, exit} = hint

    <~ @on-event hint.enter, hint.enter-delay
    view.render!
    channels.hint.publish {type: \enter, name: hint.name}

    <~ @on-event hint.exit, hint.exit-delay
    view.remove!
    channels.hint.publish {type: \exit, name: hint.name}

  on-event: (ev, delay = 0, cb = -> null) ~>
    fn = -> set-timeout cb, parse-int delay
    if ev.match /^time:\s?(\d+?)$/
      time = that.1 |> parse-int
      set-timeout fn, time
    else
      channels.parse ev .once fn

  destroy: ~> [hint.view.remove! for hint in @hints]
