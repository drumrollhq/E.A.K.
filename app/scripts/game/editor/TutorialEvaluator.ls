class Context
  (parent = null) ->
    @parent = parent
    @teardowns = []

  cleanup: ->
    for teardown in @teardowns => teardown!

  add-teardown: (fn) -> @teardowns[*] = fn

module.exports = class TutorialEvaluator
  (@ast, @tut, @store) ->
    @context = new Context!

  create-context: ->
    @context = new Context @context

  pop-context: ->
    @context.cleanup!
    @context = @context.parent

  start: ->
    @eval @ast

  eval: (arg) ->
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
    | otherwise => @eval first .then ~> @eval-list rest

  ### Builtin fns:
  log: (...args) -> console.log '[tutorial]', ...args
  wait: (timeout) -> Promise.delay timeout

  tutor: (name) -> @tut.set 'tutor', name

  step: (id, ...step) ->
    @tut.create-step id
    @create-context!
    @eval step .then ~> @pop-context!

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
    @log lines

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
