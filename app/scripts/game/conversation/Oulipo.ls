binary-ops = {
  '&':  (a, b) -> a and b
  '|':  (a, b) -> a or b
  '==': (a, b) -> a is b
  '!=': (a, b) -> a isnt b
  '<':  (a, b) -> a < b
  '>':  (a, b) -> a > b
  '<=': (a, b) -> a <= b
  '>=': (a, b) -> a >= b
  '+':  (a, b) -> a + b
  '-':  (a, b) -> a - b
  '*':  (a, b) -> a * b
  '/':  (a, b) -> a / b
}

unary-ops = {
  '!':  (a) -> not a
}

module.exports = class Oulipo
  (@start-id, @nodes, @state) ->
    _.extend this, Backbone.Events

  start: ->
    @process-node @start-id

  process-node: (id) ->
    if typeof id is \string then node = @nodes[id] else node = id

    switch node.type
      case \line
        @say-line node.name, node.content
          .then ~> @process-node node.next

      case \choice
        choices = node.choices.filter (choice) ~>
          unless choice.condition then return true
          return choice.condition.is is !!@eval-expression choice.condition.expression

        content = choices.map ( .content )

        decide = new Promise (resolve) ~> @trigger \choice, node.name, content, resolve
        decide
          .tap (idx) ~> @say-line node.name, choices[idx].content, true
          .then (idx) ~> @process-node choices[idx].next

      case \set
        @set node.variable, node.op, node.value
        @process-node node.next

      case \go, \note, \continue
        @process-node node.next

      case \exec
        fn = new Function \eak, \channels, node.js
        fn window.eak, require 'lib/channels'

      case \branch
        for branch in node.branches
          if branch.condition.is?.default?
            def = branch.next
            continue

          if branch.condition.is is @eval-expression branch.condition.expression
            return @process-node branch.next

        if def
          return @process-node def
        else
          console.log '[oulipo]' node
          throw new error 'No default and no valid condition in branch'

      default
        console.log '[oulipo]' node
        throw new TypeError "[oulipo] Unknown node type #{node.type}"

  say-line: (name, content, from-player) ->
    @state.add-line name, content, from-player
    Promise.delay 1500

  set: (variable, op, value) ->
    variable = camelize variable
    switch op
    | \= => @state.set variable, value
    | otherwise => throw new Error "Cannot set #variable #op #{JSON.stringify value}: unknown operator #op"

  eval-expression: (exp) ->
    switch exp.type
    | \expression => @eval-expression exp.exp
    | \operator => binary-ops[exp.op] (@eval-expression exp.left), (@eval-expression exp.right)
    | \unary => unary-ops[exp.op] (@eval-expression exp.exp)
    | \identifier => @state.get camelize exp.val
    | <[number boolean string]> => exp.val
    | otherwise =>
        console.log '[oulipo]' exp
        throw new TypeError "[oulipo] Unknown expression type #{exp.type}"
