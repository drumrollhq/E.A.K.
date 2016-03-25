require! {
  'audio/popcorn'
  'game/editor/components/FadeIn'
}

say-id-counter = 0

module.exports = class Tutorial extends Backbone.DeepModel
  start: ->
    @trigger \setup
    @play-step (@get \step-order.0)

  stop: ->
    @trigger \stop
    if @_step-pr and @_step-pr.is-pending! then @cancel-step!

  play-step: (id, user-req = false) ->
    if @_step-pr and @_step-pr.is-pending! then @cancel-step!
    step = @get "steps.#{id}"
    @set "steps.#{id}.shown", true
    Promise.resolve @_step-pr
      .catch (e) -> # eh
      .then ~>
        if not user-req and step.options.skip-if and step.options.skip-if! then return true
        @_play-step step
      .then (finished) ~>
        unless finished then return
        step-idx = @get \step-order .index-of id
        next-step = @get "step-order.#{step-idx + 1}"
        if next-step and not next-step.shown
          Promise.delay 500 .then ~>
            @play-step next-step

  _play-step: ({track, fn, options}) ->
    @_waiting-for = []
    @_teardowns = []
    @_step-options = options

    @audio = audio = popcorn (@get \audio-root), track
    audio-pr = new Promise (resolve) ~>
      @audio.on \ended, -> resolve true

    @_waiting-for[*] = fn!
    @audio.play!

    @_step-pr = audio-pr
      .cancellable!
      .catch Promise.CancellationError, ->
        audio.pause!.destroy!
        false
      .tap ~> Promise.all @_waiting-for
      .catch (e) ->
        # TODO: be less shit and actually handle this.
        false
      .tap ~> @teardown!

  cancel-step: !->
    @_step-pr.cancel!
    for promise in @_waiting-for when Promise.is promise and promise.is-cancellable!
      promise.cancel!

  teardown: !->
    unless @_teardowns then return
    for teardown in @_teardowns
      teardown.apply this

    @_teardowns = null

  add-teardown: (fn) -> @_teardowns[*] = fn

  # Tutorial builder functions:
  setup: (fn) -> @on \setup, fn, this

  step: (id, track, options, fn) ->
    if typeof options is \function
      fn = options
      options = {}

    if @get "steps.#{id}" then return
    @set "steps.#id", {track, fn, options}
    step-order = @get \step-order or []
    step-order.push id
    @set \step-order step-order

  target: ->

  # Tutorial control functions
  at: (t, fn) ->
    @audio.cue t, ~> @_waiting-for[*] = fn.apply this
    return this

  show-at: (t, children) ->
    wait-for = new Promise (resolve) ~> @audio.cue t, resolve
    React.create-element FadeIn, {wait-for}, children

  say: (msg, options = {}) ->
    @set 'msg', null
    @set 'msg', {msg, options, id: say-id-counter++}
    unless @_step-options.keep-say then @add-teardown ~> @set 'msg' null
    return this

  await-select: (selector) ->
    wait-for-event @editor-view.cm, \cursorActivity, condition: (cm) ~>
      ranges = @editor-view.select selector
      pos = cm.index-from-pos cm.get-cursor!
      for range in ranges when range.start <= pos <= range.end
        return true

  await-event: (name, options = {}) ->
    wait-for-event @editor-view, name, options

  wait: (t) ->
    Promise.delay t * 1000
      .cancellable!
      .catch Promise.CancellationError, -> # meh

  lock-code: (selector) ->
    ranges = @editor-view.select selector
    for range in ranges => @editor-view.extras.mark-readonly range
    return this

  unlock-code: (selector) ->
    ranges = @editor-view.select selector
    for range in ranges => @editor-view.extras.clear-readonly range
    return this

  highlight-code: (selector) ->
    ranges = @editor-view
      .select selector
      .map (range) ~> @editor-view.extras.highlight range

    @add-teardown ~> ranges.for-each ( .clear! )
    return this

  highlight-dom: (selector, $within = $body) ->
    @highlights ?= []
    @add-teardown ~> @clear-highlight!
    for el in $within.find selector
      $el = $ el
      $parent = $el.offset-parent!
      rect = el.get-bounding-client-rect!
      parent-rect = $parent.get 0 .get-bounding-client-rect!

      @highlights[*] = $ '<div></div>'
        .add-class \action-highlight
        .css do
          top: rect.top - parent-rect.top
          left: rect.left - parent-rect.left
          width: $el.outer-width!
          height: $el.outer-height!
        .append-to $parent

    return this

  highlight-level: (selector) ->
    @highlight-dom selector, @editor-view.render-el

  clear-highlight: ->
    @editor-view.extras.clear-highlight!
    for highlight in @[]highlights => highlight.remove!
    @highlights = null
    return this

  save: -> @editor-view.save!
  reset: -> @editor-view.reset!
  cancel: -> @editor-view.cancel!
  undo: -> @editor-view.undo!
  redo: -> @editor-view.redo!
