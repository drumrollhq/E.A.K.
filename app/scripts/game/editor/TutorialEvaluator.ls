require! {
  'audio/play-conversation-line'
}

module.exports = class TutorialEvaluator
  (@ast, @tut, @store) ->
    @tut.on 'exec-step' (step-id) !~>

  log: (...args) -> console.log '[tutorial]', ...args
  wait: (timeout) -> Promise.delay timeout
  set: (key, val) -> @tut.set (camelize key), val
  get: (key) -> @tut.get camelize key

  step: (id, track, fn) ->
    @tut.create-step id, track, fn

  target: (id, options, condition) ->
    target = @tut.create-target id
    pr = new Promise (resolve) ~>
      check = ~>
        if condition {$: @tut.render-el.find}
          @tutorial.editor-view.off \change, check
          resolve!

      @tutorial.editor-view.on \change, check
      check!

    pr = pr.then ~> @tut.complete-target id
    if options.block then return pr

  await-select: (selector) ->
    wait-for-event @tut.editor-view.cm, \cursorActivity, condition: (cm) ~>
      ranges = @tut.editor-view.select selector
      pos = cm.index-from-pos cm.get-cursor!
      for range in ranges when range.start <= pos <= range.end
        return true

  await-event: (name, options = {}) ->
    wait-for-event @tut.editor-view, name, options

  say: (id, options, lines) ->
    promise = play-conversation-line (@tut.get \audioRoot), id
    @context.wait-for promise
    if options.async then return null else return promise

  lock: (selector) ->
    ranges = @tut.editor-view.select selector
    for range in ranges => @tut.editor-view.extras.mark-readonly range

  unlock: (selector) ->
    ranges = @tut.editor-view.select selector
    for range in ranges => @tut.editor-view.extras.clear-readonly range

  highlight-code: (selector) ->
    ranges = @tut.editor-view
      .select selector
      .map (range) ~> @tut.editor-view.extras.highlight range

    @context.add-teardown ~> ranges.for-each ( .clear! )

  highlight-level: (selector) ->
    @context.highlights ?= []
    @context.add-teardown ~> @clear-highlight!
    for el in @tut.editor-view.render-el.find selector
      $el = $ el
      $parent = $el.offset-parent!
      rect = el.get-bounding-client-rect!
      parent-rect = $parent.get 0 .get-bounding-client-rect!

      @context.highlights[*] = $ '<div></div>'
        .add-class \action-highlight
        .css do
          top: rect.top - parent-rect.top
          left: rect.left - parent-rect.left
          width: $el.outer-width!
          height: $el.outer-height!
        .append-to $parent

  clear-highlight: ->
    @tut.editor-view.extras.clear-highlight!
    for highlight in @context.[]highlights => highlight.remove!
    @context.highlights = null

  save: -> @tut.editor-view.save!
  reset: -> @tut.editor-view.reset!
  cancel: -> @tut.editor-view.cancel!
  undo: -> @tut.editor-view.undo!
  redo: -> @tut.editor-view.redo!
