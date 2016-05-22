require! {
  'audio/context'
  'audio/tracks'
  'lib/channels'
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
    @_multiplier-node = context.create-gain!
    @node.connect @_multiplier-node
    @_multiplier-node.connect nodes.master
    @_mult = 1
    nodes[@name] = @node
    tracks.add @name, this

  fade: (value, duration = 0.5) ->
    @_multiplier-node.gain.set-value-at-time @_mult, context.current-time
    @_multiplier-node.gain.linear-ramp-to-value-at-time value, context.current-time + duration
    @_mult = value
