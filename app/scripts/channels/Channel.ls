require! 'channels/Subscription'

id = 0
debug = false

checker = (channel) ->
  allowed-keys = keys channel.schema
  props = [{...prop, name: key} for key, prop of channel.schema]
  required = props |> filter ( .required ) |> map ( .name )
  typed = props |> filter ( .type )

  (data) ->
    data-keys = keys data
    for key in data-keys when key not in allowed-keys
      throw new TypeError "Key '#key' not allowed in channel '#{channel.name}'"

    for key in required when key not in data-keys
      throw new TypeError "Missing required key '#key' in channel '#{channel.name}'"

    for prop in typed
      actual = (typeof! data[prop.name]).to-lower-case!
      extpected = prop.type
      if actual isnt extpected
        unless prop.optional and actual is 'undefined'
          throw new TypeError "Expected type of '#{prop.name}' to be '#extpected', but got '#actual' in channel '#{channel.name}'"

module.exports = class Channel
  ({name = '!anonymous', @schema = {}, @parse}, @_read-only = false) ->
    @name = camelize name
    @_check = checker this
    @id = "#{id++}/#{@name}"
    @_handlers = []
    @_onces = []

  _sub: (handler) ~>
    @_handlers[*] = handler
    if debug then console.log '_sub:' @id, (new Error()).stack

  _unsub: (handler) ~>
    b = @_handlers.length
    @_handlers .= filter ( isnt handler )
    @_onces .= filter ( isnt handler )
    if debug then console.log '_unsub:' @id, (new Error()).stack

  subscribe: (handler) ~> new Subscription this, handler
  once: (handler) ~> @_onces[*] = handler

  unsubscribe: (arg) ~>
    if typeof! arg isnt 'Function'
      if arg.handler?
        handler = sub.handler
        if arg.unsubscribe? then return arg.unsubscribe!
      else
        throw new TypeError 'unsubscribe can only take a function or subscription!'
    else
      handler = arg

    @_unsub handler

  _publish: (data) ~>
    todo = @_handlers ++ @_onces
    @_onces = []
    [handler data for handler in todo]

  publish: (data) ~>
    if @_read-only
      throw new TypeError "Cannot publish on read-only channel #{@id}"

    @_check data
    @_publish data

  publish-sync: (data) ~>
    if @_read-only
      throw new TypeError "Cannot publish on read-only channel #{@id}"

    @_check data
    @_publish data

  map: (fn) ~>
    new-chan = new Channel {}, true
    @subscribe (data) -> new-chan._publish data
    new-chan

  filter: (fn) ~>
    new-chan = new Channel {}, true
    @subscribe (data) -> if fn data then new-chan._publish data
    new-chan
