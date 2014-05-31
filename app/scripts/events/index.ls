channels = <[frame]>

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

id = 0
get-channel = (file) ->
  channel = require "events/#file"
  channel.id = "#{id++}/#{channel.name}"

  check = checker channel

  channel.subscribe = (handler) -> PubSub.subscribe channel.id, handler
  channel.unsubscribe = (handler) -> PubSub.unsubscribe channel.id, handler
  channel.publish = (data = {}) ->
    check data
    PubSub.publish channel.id, data

  channel

to-obj-by = (fn, xs) --> {[(fn x), x] for x in xs}

module.exports = channels |> map get-channel |> to-obj-by ( .name )

