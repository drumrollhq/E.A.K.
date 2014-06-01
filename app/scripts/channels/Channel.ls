require! 'channels/Subscription'

id = 0

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
        throw new TypeError "Expected type of '#{prop.name}' to be '#extpected', but got '#actual' in channel '#{channel.name}'"

module.exports = class Channel
  ({name = '!anonymous', @schema = {}}, @_read-only = false) ->
    @name = camelize name
    @_check = checker this
    @id = "#{id++}/#{@name}"

  subscribe: (handler) ~> new Subscription this, handler

  publish: (data) ~>
    if @_read-only
      throw new TypeError "Cannot publish on read-only channel #{@id}"

    @_check data
    PubSub.publish @id, data

  map: (fn) ~>
    new-chan = new Channel {}, true
    @subscribe (data) -> PubSub.publish new-chan.id, fn data
    new-chan

  filter: (fn) ~>
    new-chan = new Channel {}, true
    @subscribe (data) -> if fn data then PubSub.publish new-chan.id, data
    new-chan
