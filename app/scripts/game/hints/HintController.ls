require! {
  'game/hints/Alert'
  'game/hints/Pointer'
  'lib/channels'
}

hint-types = pointer: Pointer, alert: Alert

id-counter = 1

module.exports = class HintController extends Backbone.Model
  defaults: hints: []

  hint-defaults:
    type: \alert
    target: \.player
    content: 'You forgot to add content to your hint!'
    class: 'normal'
    enter: \time:1
    exit: \time:4
    enter-delay: 0
    exit-delay: 0
    position: \below
    focus: false

  initialize: ->
    hint-els = @get \hints
    @store = @get \store

    @hints = []

    hint-els.each (i, el) ~>
      $el = $ el
      obj =
        type: ($el.attr 'hint-type') or el.tag-name.to-lower-case!
        target: ($el.attr 'target') or HintController::hint-defaults.target
        name: ($el.attr 'name') or undefined
        content: $el.html! or HintController::hint-defaults.content
        class: ($el.attr 'class') or HintController::hint-defaults.class
        enter: ($el.attr 'enter') or HintController::hint-defaults.enter
        exit: ($el.attr 'exit') or HintController::hint-defaults.exit
        enter-delay: ($el.attr 'enter-delay') or HintController::hint-defaults.enter-delay
        exit-delay: ($el.attr 'exit-delay') or HintController::hint-defaults.exit-delay
        position: ($el.attr 'position') or HintController::hint-defaults.position
        scoped: ($el.attr 'scoped')?
        scope: $el.attr 'scope'
        focus: ($el.attr 'focus')?

      obj.id = "hint_#{obj.type}_#i"
      obj.disabled = !! @store.get "state.hints.#{obj.id}"
      @hints.push obj

    [@setup hint for hint in @hints]

  activate: ->
    for hint in @hints
      if hint.start-sub?.resume? => hint.start-sub.resume!
      if hint.stop-sub?.resume? => hint.stop-sub.resume!

  deactivate: ->
    for hint in @hints
      if hint.start-sub?.pause? => hint.start-sub.pause!
      if hint.stop-sub?.pause? => hint.stop-sub.pause!

  setup: (hint) ->
    id-counter += 1

    HintController::hint-defaults.name = "hint-#{id-counter}"

    hint = _.defaults hint, HintController::hint-defaults

    if hint.scoped and not hint.scope? then hint.scope = @get 'scope'

    view = new hint-types[hint.type] hint

    hint <<< {view}

    hint.start-sub = @on-event hint.enter, hint.enter-delay, ~>
      view.render! unless hint.disabled
      channels.hint.publish {type: \enter, name: hint.name}
      if hint.start-sub.unsubscribe then hint.start-sub.unsubscribe!

      hint.stop-sub = @on-event hint.exit, hint.exit-delay, ~>
        view.remove! unless hint.disabled
        channels.hint.publish {type: \exit, name: hint.name}
        @store.patch-state {hints: "#{hint.id}": true}
        if hint.stop-sub.unsubscribe then hint.stop-sub.unsubscribe!
        hint.disabled = true

  on-event: (ev, delay = 0, cb = -> null) ~>
    fn = -> set-timeout cb, parse-int delay
    if ev.match /^time:\s?(\d+?)$/
      time = that.1 |> parse-int
      set-timeout fn, time
    else
      channels.parse ev .once fn

  destroy: ~> [hint.view.remove! for hint in @hints]
