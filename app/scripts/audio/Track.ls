require! {
  'audio/context'
  'audio/tracks'
  'channels'
}

unless context then return module.exports = false

nodes = {}

nodes.master = context.create-gain!
nodes.master.connect context.destination

channels.track-volume.subscribe ({track, value}) ->
  nodes[track].gain.value = value

module.exports = class Track
  (@name) ->
    @node = context.create-gain!
    @multiplier-node = context.create-gain!
    @node.connect @multiplier-node
    @multiplier-node.connect nodes.master
    nodes[@name] = @node
    tracks.add @name, this

  fade: (value, duration = 0.5) ->
    @multiplier-node.gain.set-value-at-time @multiplier-node.gain.value, context.current-time
    @multiplier-node.gain.linear-ramp-to-value-at-time value, context.current-time + duration
