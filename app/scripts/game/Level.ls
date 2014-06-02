require! {
  'channels'
  'game/dom/Mapper'
  'game/event-loop'
  'game/editor/Editor'
  'game/editor/EditorView'
  'game/hints/HintController'
  'game/physics'
  'game/Renderer'
  'game/Player'
  'game/Targets'
  'game/mediator'
  'loader/ElementLoader'
  'loader/LoaderView'
  'logger'
}

{map, reduce} = _

module.exports = class Level extends Backbone.Model
  initialize: (level) ->
    @subs = []
    @level = level
    conf = @conf = {}

    # Set up the HTML/CSS for the level
    conf.html = level.find 'body' .html!
    conf.css = level.find 'style' |> map _, (-> $ it .text!) |> join '\n\n'

    renderer = @renderer = new Renderer html: conf.html, css: conf.css, root: $ \#levelcontainer

    # Find and prepare the background image
    if bg = level.find 'meta[name=background]' .attr \value
      renderer.el.style.background = bg
      mediator.trigger 'prepareBackground', bg
      mediator.trigger 'showBackground'
      @conf.background = bg
      mediator.once 'background-applied' -> channels.game-commands.publish command: \loaded
    else
      <- set-timeout _, 0
      channels.game-commands.publish command: \loaded

    # Set the level size
    if size = level.find 'meta[name=size]' .attr \value
      [w, h] = size / ' '
      w = parse-float w
      h = parse-float h
    else
      w = h = 100

    conf.width = w
    conf.height = h
    renderer.set-width w
    renderer.set-height h

    # Set player coordinates
    if player = level.find 'meta[name=player]' .attr \value
      [x, y] = player / ' '
      x = parse-float x
      y = parse-float y
    else
      x = y = 0

    # Set player colour
    colour = (level.find 'meta[name=player-color]' .attr \value) or 'black'

    conf.player = {x, y, colour}

    # Find borders
    if borders = level.find 'meta[name=borders]' .attr \value
      borders = borders / ' '
    else
      borders = <[ all ]>

    if borders.0 is 'all' then borders = <[ top bottom left right ]>
    if borders.0 is 'none' then borders = []

    conf.borders = borders

    # add-targets is a function that adds targets to Renderer.
    add-targets = Targets renderer

    if targets = level.find 'meta[name=targets]' .attr \value then add-targets targets

    'head hidden' |> level.find |> ( .children! ) |> ( .add-class 'entity' ) |> @renderer.append

    loader = new ElementLoader el: @renderer.$el
    loader-view = new LoaderView model: loader
    loader-view.hide-progress!
    loader-view.$el.append-to '#main > .app'

    loader-view.render!

    event-loop.pause!
    mediator.paused = true

    <~ channels.game-commands.filter ( .command is 'loaded' ) .once

    do
      <~ loader.once 'done', _
      $.hide-dialogues!
      <~ set-timeout _, 600

      $ document.body .add-class \playing

      event-loop.resume!
      mediator.paused = false

      nodes = []
      @add-bodies-from-dom nodes
      @add-player nodes, conf.player
      @add-borders nodes, conf.borders

      state = @state = physics.prepare nodes

      @hint-controller = new HintController hints: (level.find 'head hints' .children!)

      @subs[*] = channels.game-commands.filter ( .command is \edit ) .subscribe @start-editor
      @subs[*] = channels.game-commands.filter ( .command is \restart ) .subscribe @restart
      @subs[*] = channels.game-commands.filter ( .command is \stop ) .subscribe @complete
      @subs[*] = channels.frame.subscribe @frame
      # @listen-to mediator, \kittenfound, ->
      #   # TODO: proper success thing.
      #   mediator.trigger \alert 'Yay! You saved a kitten!'

    loader.start!

  frame: (data) ~>
    # Run physics simulation / player input
    @state = physics.step @state, data.t

    # Emit events caused by the simulation
    physics.events @state, mediator

    @check-player-is-in-world!

  add-bodies-from-dom: (nodes) ~>
    @renderer.$el.find 'a[href]:not(.portal)' .attr 'data-id', 'HYPERLINK'
    @renderer.$el.find 'a[href].portal'
      ..attr 'data-id' 'PORTAL'
      ..attr 'data-sensor' 'data-sensor'

    # Build a map of some elements
    dom-map = @renderer.create-map!

    @dom-bodies = for shape in dom-map
      nodes[*] = shape
      shape.from-dom-map = true

  remove-DOM-bodies: ~>
    for node, i in @state.nodes when node.from-dom-map is true
      node.destroy!

  add-player: (nodes, player-conf) ~>
    if @player?
      nodes[*] = @player
      @player.prepared = false

    else
      player = new Player player-conf, @renderer.width, @renderer.height
      player.$el.append-to @renderer.$el
      player.id = "#{@renderer.el.id}-player"
      player.$el.attr id: player.id
      @player = player

      # Get starting positions
      @start-pos = player: player.el.get-bounding-client-rect!

      # Add player to physics
      nodes[*] = player

  restart: ~>
    logger.log 'restart', parent: @event-id
    @renderer.resize!
    @redraw-from @conf.html, @conf.css
    @player.reset!

  redraw-from: (html, css) ~>
    # Preserve entities
    entities = @renderer.$el.children \.entity .detach!

    @renderer.set-HTML-CSS html, css

    # Reset DOM bodies
    @remove-DOM-bodies!

    # Restore entities
    entities.append-to @renderer.$el

    nodes = []
    @add-bodies-from-dom nodes
    @add-player nodes, @conf.player
    @add-borders nodes, @conf.borders

    state = @state = physics.prepare nodes

  add-borders: (nodes, borders = []) ->
    if borders is \none then return
    if borders is \all then borders = top: true, right: true, left: true, bottom: true

    const t = 400px

    w = @w = @renderer.width
    h = @h = @renderer.height

    if 'top' in borders then nodes[*] = {
      type: 'rect'
      width: w * 2
      height: t
      x: 0
      y: -t / 2
      id: \BORDER_TOP
    }

    if 'bottom' in borders then nodes[*] = {
      type: 'rect'
      width: w * 2
      height: t
      x: 0
      y: h + t / 2
      id: \BORDER_BOTTOM
    }

    if 'right' in borders then nodes[*] = {
      type: 'rect'
      width: t
      height: h * 2
      x: w + t / 2
      y: 0
      id: \BORDER_RIGHT
    }

    if 'left' in borders then nodes[*] = {
      type: 'rect'
      width: t
      height: h * 2
      x: -t / 2
      y: 0
      id: \BORDER_LEFT
    }

  check-player-is-in-world: !~>
    pos = @player.p

    const xpad = 100, pad-top = 100, pad-bottom = 200

    unless (-xpad < pos.x < @w + xpad) and (-pad-top < pos.y < @h + pad-bottom)
      mediator.trigger \falloutofworld

  complete: ({payload = {handled: false, callback: -> null}}) ~>
    # If a status object is passed, set 'handled' to true. This is so that if this was triggered
    # by an event, it can know whether or not to wait for callback. Kinda hacky.
    payload.handled = true
    callback = payload.callback or -> null

    if @stopped then return

    @stopped = true

    @trigger 'done'

    $player-target = $ '<div></div>'
    $player-target.css do
      position: \absolute
      top: 0, left: 0, bottom: 0, right: 0

    $player-target.append-to document.body

    $player-el = @player.$el
    $target-el = @renderer.$el.children '[data-target]'

    $player-el.append-to $player-target
    $target-el.append-to $player-target

    $player-el.css position: \absolute
    $target-el.css position: \absolute

    $player-el.css @start-pos.player.{top, left, width, height}
    if @start-pos.target? then $target-el.css @start-pos.target.{top, left, width, height}

    @hint-controller.destroy!

    <~ @renderer.remove

    # approx center
    p = $player-el.0.get-bounding-client-rect!
    px = p.left + p.width / 2
    py = p.top + p.height / 2

    if $target-el.0?
      t = $target-el.0.get-bounding-client-rect!
      tx = t.left + t.width / 2
      ty = t.top + t.height / 2

      cx = (px + tx) / 2
      cy = (py + ty) / 2

    else
      cx = px
      cy = py

    $player-target.css (Modernizr.prefixed "transformOrigin"), "#{cx}px #{cy}px"
    $player-target.add-class \level-entity-fadeout

    <~ set-timeout _, 500

    $player-target.remove!
    delete @state
    @player.remove!
    channels.game-commands.publish command: \level-out
    for sub in @subs => sub.unsubscribe!
    @stop-listening!
    callback!

  start-editor: ~>
    if $ document.body .has-class \editor then return

    edit-event = undefined
    logger.start 'edit', parent: @event-id, (event) -> edit-event := event

    # Put the play back where they started
    @player.reset!

    # Wait 2 frames so we can ensure that the player has reset before continuing
    <~ channels.frame.once
    <~ channels.frame.once

    event-loop.pause!
    mediator.paused = true

    @renderer.clear-transform!

    editor = new Editor {
      renderer: @renderer
      original-HTML: @conf.html
      original-CSS: @conf.css
    }

    editor-view = new EditorView model: editor, render-el: @renderer.$el, el: $ \#editor
    editor-view.render!
    editor-view.$el.append-to $ \#editor

    @renderer.editor = true
    @renderer.resize!

    @renderer.clear-transform!

    <~ editor.once \save _

    if edit-event then edit-event.stop!
    logger.log 'edit-finish', {
      html: editor.get \html
      css: editor.get \css
    }

    editor-view.restore-entities!
    editor-view.remove!
    @renderer.editor = false
    @renderer.resize!
    @redraw-from (editor.get \html), (editor.get \css)
    mediator.paused = false
    event-loop.resume!
