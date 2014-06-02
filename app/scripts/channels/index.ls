require! 'channels/Channel'

channels = <[frame pre-frame post-frame key-press key-up key-down game-commands player-position
  levels window-size alert]>

id = 0
get-channel = (file) ->
  channel = require "channels/schema/#file"
  new Channel channel

to-obj-by = (fn, xs) --> {[(fn x), x] for x in xs}

module.exports = channels |> map get-channel |> to-obj-by ( .name )

