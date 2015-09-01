exports, require, module <- require.register 'minigames/urls/URLMiniGameView'

require! {
  'assets'
  'game/event-loop'
  'game/scene/Camera'
  'game/scene/Scene'
  'game/scene/WebglLayer'
  'lib/channels'
  'lib/get-at'
  'lib/keys'
  'lib/math/ease'
  'lib/set-at'
  'minigames/urls/GraphMap'
  'minigames/urls/WalkingMap'
  'minigames/urls/Zoomer'
  'minigames/urls/components/URLMinigameComponent'
  'minigames/urls/maps'
}

const width = 2000px
const height = 1800px
const player-scale = 0.6
const transition-speed = 1000ms

module.exports = class URLMiniGameView extends Backbone.View
  initialize: ({start, exit = true}) ->
    # Basic camera+scene boilerplate
    @camera = new Camera {width, height}, 0.1, -300, \centered
    @layer = new WebglLayer {width, height}
    @scene = new Scene {width, height}, @camera
    @scene.add-layers @layer

    # Make sure the scene and camera keep track of the window size
    @scene.set-viewport-size channels.window-size.value.width, channels.window-size.value.height
    @window-sub = channels.window-size.subscribe ({width, height}) ~>
      @scene.set-viewport-size width, height

    @player = new PIXI.Sprite.from-image '/minigames/urls/assets/arca-head.png', \url
    @player.anchor <<< x: 0.5, y: 0.5
    @player <<< width: 60 * player-scale, height: 55 * player-scale
    @layer.add @player, 4
    @player.target-scale = player-scale

    # Map:
    @map = new GraphMap @layer, @player, maps.main-map <<< {
      width
      height
      current-node: start
      exit: exit
    }

    @towns = {}
    for name, [x, y] of maps.towns
      town = new WalkingMap @camera, @layer, @player, maps[name] <<< {width, height}
        ..position <<< {x, y}
        ..on \path, (path) ~> @set-actual-path path

      @towns[name] = town

    @camera.track @map.player, true

    @zoomer = new Zoomer @camera, @player, @map, @towns, true
    @layer.add @zoomer, 1, true

    @map.on \arrive, (loc) ~>
      domain = @map.graph[loc].domain
      @url-component.set-state actual: [\http, domain]
      if @towns[loc] then @zoomer.zoom-to loc

    @zoomer.on \zoom-out ~> @map.exit!

  remove: ->
    super!
    @map.destroy!
    for _, town of @towns => town.destroy!
    @zoomer.destroy!
    @layer.remove!
    @scene.remove!

  load: ->
    @map.setup!
    for name, town of @towns
      town
        ..setup!
        ..set-viewport 0, 0, width, height

    @$react-cont = $ '<div class="urls-minigame"></div>'
    @react-component = React.render (React.create-element URLMinigameComponent, {
      on-correct: ~> @trigger \correct
      on-incorrect: ~> @trigger \incorrect
      on-valid-url: (url) ~> @trigger \valid-url, url
      valid-urls: @get-valid-urls!
    }), @$react-cont.0

    @url-component = @react-component.refs.url
    @url-entry = @react-component.refs.url-entry
    @help = @react-component.refs.help

    @on \correct ~>
      @react-component.set-state correct: true
      @url-component.set-state correct: true

  start: ->
    @$el
      .append @scene.el
      .append @$react-cont
      .add-class \active

    @map.activate false

  set-target-url: (protocol, domain, ...path) ->
    @url-component.set-state target: [protocol, domain, ...path]

  set-actual-path: (path) ->
    @has-set-path = true
    if path is @_last-path-set then return
    @_last-path-set = path

    if path?
      parts = path.split '/'
    else
      parts = []

    @url-component.set-state actual: [@url-component.state.actual.0, @url-component.state.actual.1, ...parts]

  set-target-image: (img, correct = @react-component.state.correct) ->
    @react-component.set-state {correct, target-img: assets.load-asset img, \url}

  step: (t) ->
    @camera.step t
    @scene.step t
    @map.step t
    @zoomer.step t

    @has-set-path = false
    for _, town of @towns => town.step t
    unless @has-set-path then @set-actual-path null

    @player.width = 60 * @player.target-scale / @camera.zoom
    @player.height = 55 * @player.target-scale / @camera.zoom

  start-url-entry-mode: (start-url) ->
    @player.visible = false
    @url-component.set-state hidden: true
    @url-entry.activate start-url
    @camera.pause-tracking!
    event-loop.pause-keys!
    keys.reset!
    @on \valid-url, @_valid-url-handler

  stop-url-entry-mode: ->
    @player.visible = true
    @url-entry.deactivate!
    event-loop.resume-keys!
    @camera.resume-tracking!
    @off \valid-url, @_valid-url-handler

  _valid-url-handler: (url = []) ->
    if @_last-valid-url === url then return
    @_last-valid-url = url

    if not @_moving-to-valid-url
      @move-to-url url

  move-to-url: (url) ->
    zoom = initial url
    current-zoom = @_current-zoom or []
    position = last url or x: width/2, y: width/2

    @_moving-to-valid-url = true
    @_current-zoom = zoom
    [zoom-out, zoom-in] = @get-zooms current-zoom, zoom
    @camera.locked = false

    Promise
      .each zoom-out, (lvl, i) ~>
        if i is zoom-out.length - 1 and empty zoom-in
          pos = position
        else
          pos = x: width/2, y: width/2

        if window.dbg-zoom then debugger
        @get-zoomer lvl .zoom-out pos: pos, activate: false, emit: false
      .then ~>
        Promise.each zoom-in, (lvl, i) ~>
          if i is zoom-in.length - 1
            pos = position
          else
            pos = x: width/2, y: height/2
          if window.dbg-zoom then debugger
          @get-zoomer lvl .zoom-to (last lvl), start-pos: pos, activate: false, emit: false
      .then ~>
        @camera.set-subject position
        [x, y] = @camera.centered!
        @camera.animate-to x, y, 1, 500
      .then ~>
        if url === @_last-valid-url
          @_moving-to-valid-url = false
          @camera.locked = true
        else
          @move-to-url @_last-valid-url

  get-zooms: (current-zoom = [], target-zoom = []) ->
    for [current, target], i in _.zip current-zoom, target-zoom
      if current isnt target
          current-zoom = current-zoom.map (_, i) -> take i + 1, current-zoom
          target-zoom = target-zoom.map (_, i) -> take i + 1, target-zoom
          zoom-out = current-zoom
            |> drop i
            |> reverse
          zoom-in = target-zoom
            |> drop i
          return [zoom-out, zoom-in]

    return [[] []]

  get-zoomer: (path, zoomer = @zoomer) ->
    | path.length is 1 => zoomer
    | otherwise => @get-zoomer (tail path), zoomer.sub-levels[first path].zoomer

  get-valid-urls: ->
    urls = {}
    for id, town of @towns
      paths = @paths-in-town [id], town
      path-obj = {}
      for path, route of paths
        set-at path-obj, path + '/_path', route, sep: '/', overwrite: false

      urls[@map.graph[id].domain] = path-obj
      urls[@map.graph[id].domain]._path = [{
        x: town.position.x + town.width / 2
        y: town.position.y + town.height / 2
      }]

    urls

  paths-in-town: (route, town) ->
    paths = {}
    for rect in town.rects when rect.4?.0 is \path
      paths[rect.4.1] = route ++ [x: rect.0 + rect.2 / 2, y: rect.1 + rect.3 / 2]

    for id, building of town.buildings
      paths = {} <<< (@paths-in-town route ++ [id], building) <<< paths

    paths
