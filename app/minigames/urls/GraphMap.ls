exports, require, module <- require.register 'minigames/urls/GraphMap'

require! {
  'assets'
  'game/scene/TiledSpriteContainer'
  'lib/channels'
  'lib/keys'
  'lib/math/Vector'
  'lib/math/Line'
}

player-scale = 0.7

opposite-directions = left: \right, right: \left, up: \down, down: \up
directions = right: 0, left: -Math.PI, up: -Math.PI/2, down: Math.PI/2

angle-to-directions = (b) ->
  directions
    |> Obj.map (a) -> Math.min (Math.abs a - b), 2*Math.PI - (Math.abs a - b)
    |> Obj.filter (a) -> a < Math.PI / 3

connect = (a, b) ->
  angle = a.position.angle-to b.position
  directions = angle-to-directions angle
  for own direction, distance of directions
    if (not a.connections[direction]) or (a.connections[direction].disance < distance)
      line = new Line a.position, b.position
      a.connections[direction] = {b.id, distance, line}

create-graph = (nodes, paths) ->
  nodes = {[id, {position: (new Vector x, y), name, id, connections: {}}] for own id, [x, y, name] of nodes}
  for [a, b] in paths
    a = nodes[camelize a]
    b = nodes[camelize b]
    connect a, b
    connect b, a

  nodes

const player-speed = 0.1px

module.exports = class GraphMap extends PIXI.Container
  ({width, height, map-url, nodes, paths, @current-node}) ->
    super!
    @bg = new TiledSpriteContainer map-url, width, height
    @add-child @bg

    @player = new PIXI.Sprite.from-image '/minigames/urls/arca-head.png'
    @player.anchor <<< x: 0.5, y: 0.5
    @player <<< {
      width: 60 * player-scale, height: 55 * player-scale
      x: nodes[@current-node].0, y: nodes[@current-node].1
    }
    @add-child @player

    @graph = create-graph nodes, paths
    @_in-transit = false

  setup: ->
    @bg.setup!

  step: (t) ->
    if @_in-transit then @animate t else @choose-direction!

  animate: (t) ->
    @_distance-travelled += t * player-speed
    if @_distance-travelled < @_line.length
      p = @_line.at @_distance-travelled
    else
      p = @_line.at @_line.length
      @_line = null
      @_distance-travelled = null
      @_in-transit = false

    @player.position <<< p.{x, y}

  choose-direction: ->
    direction =
      | keys.up => \up
      | keys.down => \down
      | keys.left => \left
      | keys.right => \right
      | otherwise => null

    node = @graph[@current-node]
    connection = node.connections[direction]
    unless connection then return
    @_line = connection.line
    @_in-transit = true
    @_distance-travelled = 0
    @current-node = connection.id

  set-viewport: (top, left, bottom, right) ->
    @bg.set-viewport top, left, bottom, right
