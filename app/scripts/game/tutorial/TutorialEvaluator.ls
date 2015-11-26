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

  say: (id, options, lines) ->
    alert (values lines).join \\n

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
