const dbg = true

id-gen = ->
  ids = {}
  gen = (type, id) ->
    ids[type] ?= 0
    return id or "#{type}-#{ids[type]++}"

node = (name, options = {}) ->
  class-fn = (...args) ->
    id = @_ids name # Unique local id
    ast = @current-ast # Keep a reference to the current AST - val can change it
    val = if typeof options is \function then options.apply this, args else options
    @log 'add-node' id, ...args
    ast.add-node name, id, val
    return this

  Tutorial.prototype[camelize name] = class-fn

class AST
  (@type, @parent = null) ->
    @_nodes = []
    @level = if @parent then @parent.level + 1 else 0

  add-node: (name, id, val) -> @_nodes[*] = {} <<< {name, id} <<< val

module.exports = class Tutorial
  ->
    @ast = @current-ast = new AST 'root'
    @_ids = id-gen!

  new-ast: (type) ->
    @log 'new-ast' type
    @current-ast = new AST type, @current-ast

  try-end: (...types) ->
    @log 'attempt try-end' types
    if @current-ast.type is \root then return
    if types.length is 0 or @current-ast.type in types
      t = @current-ast.type
      @current-ast = @current-ast.parent
      @log 'end' t

    return this

  end: (...types) ->
    @log 'attempt end' types
    if @current-ast.type is \root then throw new Error 'Cannot end root node'
    if types.length is 0 or @current-ast.type in types
      t = @current-ast.type
      @current-ast = @current-ast.parent
      @log 'end' t
      return this

    throw new Error "Cannot end #{types.join '|'} node, current node type is #{@current-ast.type}"

  log: (...args) ->
    unless dbg then return
    console.log (_.repeat \\t, @current-ast.level), ...args

node \tutor

node \lock
node \unlock

node \step, (id) ->
  ast = @new-ast \step
  {id, ast}

node \target

node \help, ->
  ast = @new-ast \help
  {ast}

node \after, ->
  ast = @new-ast \after
  {ast}

node \optional

node \say

node \wait
node \await-select
node \await-event

node \highlight-code
node \highlight-level
node \highlight-dom
node \clear-highlight

node \save
node \reset
node \cancel
