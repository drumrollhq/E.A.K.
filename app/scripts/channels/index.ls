require! 'channels/Channel'

channels = <[frame pre-frame post-frame]>

id = 0
get-channel = (file) ->
  channel = require "channels/#file"
  new Channel channel

to-obj-by = (fn, xs) --> {[(fn x), x] for x in xs}

module.exports = channels |> map get-channel |> to-obj-by ( .name )

