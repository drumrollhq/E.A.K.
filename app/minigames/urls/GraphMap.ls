exports, require, module <- require.register 'minigames/urls/GraphMap'

require! {
  'assets'
  'game/scene/TiledSpriteContainer'
  'lib/channels'
  'lib/keys'
  'lib/math/Vector'
  'lib/math/Bezier'
  'lib/math/ease'
}

directions = right: 0, left: -Math.PI, up: -Math.PI/2, down: Math.PI/2

angle-to-directions = (b) ->
  directions
    |> Obj.map (a) -> Math.min (Math.abs a - b), 2*Math.PI - (Math.abs a - b)
    |> Obj.filter (a) -> a < Math.PI / 3

connect = (a, b, c, d) ->
  angle = a.position.angle-to b.position
  directions = angle-to-directions angle
  for own direction, distance of directions
    if (not a.connections[direction]) or (a.connections[direction].disance < distance)
      line = new Bezier a.position, b.position, c, d
      a.connections[direction] = {b.id, distance, line}

create-graph = (nodes, paths) ->
  nodes = {[id, {position: (new Vector x, y), label, id, connections: {}}] for own id, [x, y, label] of nodes}
  for [a, b, [cx, cy], [dx, dy]] in paths
    a = nodes[camelize a]
    b = nodes[camelize b]
    c = new Vector cx, cy
    d = new Vector dx, dy
    connect a, b, c, d
    connect b, a, d, c

  nodes

const player-speed = 0.2px
const player-scale = 0.7
const fade-speed = 0.004

module.exports = class GraphMap extends PIXI.Container
  ({width, height, map-url, nodes, paths, @current-node, exit = false}) ->
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

    for id, [x, y, label, offset-x = 0, offset-y = 0] of nodes when label
      text = new PIXI.Text label, {
        font: '16px KG Next to Me'
        align: 'center'
        fill: 0x333333
        stroke: 'rgba(255, 255, 255, 0.5)'
        stroke-thickness: 4
      }
      text <<< {x: x + offset-x, y: y + offset-y, alpha: 0}
      @add-child text
      nodes[id] = [x, y, text]

    @graph = create-graph nodes, paths

    # Exit the current node:
    if exit
      @exit!
    else
      @_in-transit = false

  setup: ->
    @bg.setup!

  step: (t) ->
    if @_in-transit then @animate t else @choose-direction!
    @update-labels t

  animate: (t) ->
    @_distance-travelled += t * player-speed
    if @_distance-travelled < @_line.length
      p = @_line.interpolate ease.sin @_distance-travelled / @_line.length
    else
      p = @_line.at @_line.length
      @_line = null
      @_distance-travelled = null
      @_in-transit = false
      @emit 'arrived' @current-node

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
    @go connection

  update-labels: (t) ->
    for own id, node of @graph when node.label
      if @should-show-label-for node
        # Fade label in
        if node.label.alpha < 1
          node.label.alpha = Math.min 1, node.label.alpha + t*fade-speed
      else
        # Fade label out
        if node.label.alpha > 0
          node.label.alpha = Math.max 0, node.label.alpha - t*fade-speed

  should-show-label-for: (node) ->
    current = @graph[@current-node]
    if @_in-transit then return false
    # if current.id is node.id then return true
    for direction, connection of current.connections
      if connection.id is node.id then return true

    return false

  exit: ->
    current = @graph[@current-node]
    for direction, connection of current.connections
      return @go connection

  go: (connection) ->
    @_line = connection.line
    @_in-transit = true
    @_distance-travelled = 0
    @current-node = connection.id
    @emit 'go' @current-node

  set-viewport: (top, left, bottom, right) ->
    @bg.set-viewport top, left, bottom, right
