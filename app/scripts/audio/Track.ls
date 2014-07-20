require! {
  'audio/context'
  'channels'
}

nodes = {}

nodes.master = context.create-gain!
nodes.master.connect context.destination

channels.track-volume.subscribe ({track, value}) ->
  nodes[track].gain.value = value

module.exports = class Track
  (@name) ->
    @node = context.create-gain!
    @node.connect nodes.master
    nodes[@name] = @node
