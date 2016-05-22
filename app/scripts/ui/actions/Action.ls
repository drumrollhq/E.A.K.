ongoing = {}

module.exports = class Action
  (@overlay, @app, @options = {}) ->
    _.extend this, Backbone.Events

    name = @constructor.display-name
    if ongoing[name]
      ongoing[name].cancel \cancel

    ongoing[name] = this

    @listen-to @overlay, \dismiss, @dismiss
    @listen-to @overlay, \activate, @activate
    @listen-to @overlay, \deactivate, @deactivate

    @promise = new Promise (resolve, reject) ~>
      @_resolve = resolve
      @_reject = reject
      @initialize @options
    .cancellable!

  resolve: (val) ->
    @_done @_resolve, val

  reject: (val) ->
    @_done @_reject, val

  cancel: ->
    @promise.cancel!

  _done: (cb, val) ->
    @stop-listening!
    cb val

  initialize: ->
  dismiss: ->
  activate: ->
  deactivate: ->
