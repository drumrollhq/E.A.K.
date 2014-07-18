require! 'audio/context'

module.exports = class Track
  (@name) ->
    @node = context.create-gain!
    @node.connect context.destination
