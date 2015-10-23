require! {
  'game/hints/Alert'
  'game/hints/Pointer'
  'game/hints/Message'
  'lib/channels'
}

hint-types = pointer: Pointer, alert: Alert, message: Message

id-counter = 1

module.exports = class HintController extends Backbone.Model
  defaults: hints: []

  hint-defaults:
    type: \alert
    target: \.player
    from: \ada
    content: 'You forgot to add content to your hint!'
    class: 'normal'
    enter: \time:1
    exit: \time:4
    enter-delay: 0ms
    exit-delay: 0ms
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
        from: ($el.attr 'from') or HintController::hint-defaults.from
        track: ($el.attr 'track')
        name: ($el.attr 'name') or undefined
        content: $el.html! or HintController::hint-defaults.content
        timeout: ($el.attr 'timeout') or undefined
        class: ($el.attr 'class') or HintController::hint-defaults.class
        enter: ($el.attr 'enter') or HintController::hint-defaults.enter
        exit: ($el.attr 'exit') or HintController::hint-defaults.exit
        enter-delay: ($el.attr 'enter-delay') or HintController::hint-defaults.enter-delay
        exit-delay: ($el.attr 'exit-delay') or HintController::hint-defaults.exit-delay
        enter-after: ($el.attr 'enter-after') or undefined
        position: ($el.attr 'position') or HintController::hint-defaults.position
        scoped: ($el.attr 'scoped')?
        scope: $el.attr 'scope'
        focus: ($el.attr 'focus')?

      obj.id = obj.name or "hint_#{obj.type}_#i"
      obj.disabled = !! @store.get "state.hints.#{obj.id}"
      @hints.push obj

    [@setup hint for hint in @hints]

  activate: ->
    @active = true

  deactivate: ->
    @active = false

  setup: (hint) ->
    id-counter += 1

    HintController::hint-defaults.name = "hint-#{id-counter}"

    hint = _.defaults hint, HintController::hint-defaults

    if hint.scoped and not hint.scope? then hint.scope = @get 'scope'

    view = new hint-types[hint.type] hint

    hint <<< {view}

    hint._promise = @enter-after hint.enter-after
      .then ~> @on-event hint.enter
      .then ~> Promise.delay parse-int hint.enter-delay || 0
      .then ~>
        view.render! unless hint.disabled
        channels.hint.publish type: \enter, name: hint.name
        @on-event hint.exit
      .then ~> Promise.delay parse-int hint.exit-delay || 0
      .then ~>
        view.remove! unless hint.disabled
        channels.hint.publish type: \exit, name: hint.name
        # @store.patch-state hints: {"#{hint.id}": true}
        hint.disabled = true

  on-event: (event) ->
    if event.match /OR/
      events = event
        .split 'OR'
        .map ( .trim! )
        .map (event) ~>
          @on-event event .then ~> event

      Promise.any events
    else
      if event.match /^time:\s?(\d+?)$/
        time = parse-int that.1
        Promise.delay time
      else
        new Promise (resolve) ~>
          channels
            .parse event
            .filter ~> @active
            .once resolve

  enter-after: (name, cb) -> new Promise (resolve) ~>
    unless name then return resolve!
    channels.hint
      .filter (h) -> h.type is \exit and h.name is name
      .once resolve

  destroy: ~>
    for hint in @hints
      hint.view.remove!
      hint._promise.cancel!
