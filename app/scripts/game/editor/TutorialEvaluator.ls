require! {
  'audio/play-conversation-line'
}

class Context
  (parent = null) ->
    @parent = parent
    @teardowns = []
    @waiting-for = []

  cleanup: (cancel) ->
    if cancel then for promise in @waiting-for => promise.cancel!
    Promise.all @waiting-for
      .then ~> for teardown in @teardowns => teardown!

  add-teardown: (fn) -> @teardowns[*] = fn
  wait-for: (promise) -> @waiting-for[*] = promise

module.exports = class TutorialEvaluator
  (@ast, @tut, @store) ->
    @context = new Context!
    @tut.on 'exec-step' (step-id) !~>
      for node, i in ast.0 when node.0 is \step and node.1 is step-id
        rest = drop i, ast.0
        @stop-all!.then ~> @eval rest

  create-context: ->
    @context = new Context @context

  pop-context: (cancel = false) ->
    @context.cleanup cancel
      .then ~> @context = @context.parent if @context.parent

  stop-all: ->
    if @_current?.cancel then @_current.cancel!
    if @context.parent
      @pop-context true .then ~> @stop-all!
    else
      Promise.resolve!

  start: ->
    @eval @ast

  eval: (arg) ->
    console.log '[eval]', arg
    switch
    | typeof! arg is \Array and typeof! arg.0 is \String => @eval-s-exp arg
    | typeof! arg is \Array and typeof! arg.0 is \Array => @eval-list arg
    | otherwise => Promise.resolve arg

  eval-s-exp: ([name, ...args]) ->
    name = camelize name
    if typeof @[name] is \function
      Promise.resolve @[name].apply this, args
    else
      Promise.reject new Error "No such function #name"

  eval-list: ([first, ...rest]) ->
    | empty rest => @eval first
    | otherwise =>
      @_current = @eval first
      @_current.cancellable!
      @_current.then ~> @eval-list rest

  ### Builtin fns:
  log: (...args) -> console.log '[tutorial]', ...args
  wait: (timeout) -> Promise.delay timeout
  set: (key, val) -> @tut.set (camelize key), val
  get: (key) -> @tut.get camelize key

  tutor: (name) -> @tut.set 'tutor', name

  step: (id, ...step) ->
    @tut.create-step id
    ctx = @create-context!
    @eval step .then ~>
      if @context = ctx then @pop-context!

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

  once: (id, ...instructions) ->
    # TODO: only eval if a once with that id hasn't already run
    @eval instructions

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
