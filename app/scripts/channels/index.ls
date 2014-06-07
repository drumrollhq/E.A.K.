require! 'channels/Channel'

schemas = <[frame pre-frame post-frame key-press key-up key-down game-commands player-position
  levels window-size alert death hint contact kitten]>

id = 0
get-channel = (file) ->
  channel = require "channels/schema/#file"
  new Channel channel

to-obj-by = (fn, xs) --> {[(fn x), x] for x in xs}

channels = schemas |> map get-channel |> to-obj-by ( .name )
channels.schemas = schemas |> map camelize

channels.parse = (str) ->
  chans = str
    |> split ';'
    |> map ( .trim! )
    |> map channels.parse-one

  channels.merge.apply channels, chans

# channels.parse takes a string in the format "#{channel-name}:#{details}" and attempts to return
# a channels matching that description. For example, the string "key-press" will return the
# key-press channel, but the string "keypress:a,d" will return the key-press channel filtered to
# only presses of the 'a' and 'd' keys. The filter function is specified in the schema of the
# channel in question.
channels.parse-one = (str) ->
  parts = str |> split ':'
  channel-name = parts |> first |> camelize
  details = parts |> tail |> join ':'

  if channel-name not in channels.schemas
    throw new Error "Cannot parse '#str': no such channel as '#channel-name'"

  channel = channels[channel-name]
  if details is ''
    return channel
  else if channel.parse?
    return channel.filter channel.parse details
  else throw new Error "Parse not implemented on channel '#channel-name'"

channels.merge = (...chans) ->
  channel = new Channel {}, true
  for chan in chans => chan.subscribe (data) -> channel._publish data
  channel

module.exports = channels
