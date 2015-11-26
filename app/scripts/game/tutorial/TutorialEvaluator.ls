module.exports = class TutorialEvaluator
  (@ast, @tut) ->

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

  tutor: (name) -> @tut.set 'tutor', name

  lock: (selector) ->
    # if !selector then return @tut.editor-view.cm.set-option \readOnly, true
    ranges = @tut.editor-view.select selector
    for range in ranges => @tut.editor-view.extras.mark-readonly range

  unlock: (selector) ->
    # if !selector then return @tut.editor-view.cm.set-option \readOnly, false
    ranges = @tut.editor-view.select selector
    for range in ranges => @tut.editor-view.extras.clear-readonly range
