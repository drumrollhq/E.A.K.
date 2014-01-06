require! {
  'game/dom/Mapper'
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
}

{map, reduce} = _

module.exports = class Level extends Backbone.Model
  initialize: (level) ->
    @level = level
    conf = @conf = {}

    # Set up the HTML/CSS for the level
    conf.html = level.find 'body' .html!
    conf.css = level.find 'head style' |> map _, (-> $ it .text!) |> reduce _, (m, n) -> m + '\n\n' + n

    renderer = @renderer = new Renderer html: conf.html, css: conf.css, root: $ \#levelcontainer

    # Find and prepare the background image
    if bg = level.find 'meta[name=background]' .attr \value
      renderer.el.style.background = bg
      mediator.trigger 'prepareBackground', bg
      @conf.background = bg

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
    loader-view.$el.append-to '#main > .app'

    loader-view.render!

    mediator.paused = true

    do
      <~ loader.once 'done', _
      $.hide-dialogues!
      <~ set-timeout _, 600

      $ document.body .add-class \playing

      mediator.trigger 'showBackground'

      mediator.paused = false

      nodes = []
      @add-bodies-from-dom nodes
      @add-player nodes, conf.player
      @add-borders nodes, conf.borders

      state = @state = physics.prepare nodes

      @hint-controller = new HintController hints: (level.find 'head hints' .children!)

      @listen-to mediator, \edit, @start-editor
      @listen-to mediator, \restart, @restart
      @listen-to mediator, \frame:process, @frame
      # @listen-to mediator, \kittenfound, ->
      #   # TODO: proper success thing.
      #   mediator.trigger \alert 'Yay! You saved a kitten!'
      @listen-to mediator, \stop-game, @complete

    loader.start!

  frame: (dt) ~>
    # Run physics simulation / player input
    @state = physics.step @state, dt

    # Emit events caused by the simulation
    physics.events @state, mediator

    # @check-player-is-in-world!

  add-bodies-from-dom: (nodes) ~>
    # Build a map of some elements
    dom-map = @renderer.create-map!

    world = @world

    @dom-bodies = for shape in dom-map
      nodes[*] = shape
      shape.from-dom-map = true

  remove-DOM-bodies: ~>
    for node, i in @state when shape.from-dom-map is true
      @state.splice i, 1

  add-player: (nodes, player-conf) ~>
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
    @renderer.resize!
    @redraw-from @conf.html, @conf.css
    @player.body.reset!

  redraw-from: (html, css) ~>
    # Preserve entities
    entities = @renderer.$el.children \.entity .detach!

    @renderer.set-HTML-CSS html, css

    # Reset DOM bodies
    @remove-DOM-bodies!
    @add-bodies-from-dom!

    # Restore entities
    entities.append-to @renderer.$el

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
    pos <~ @player.body.position-uncorrected

    const xpad = 100, pad-top = 100, pad-bottom = 200

    unless (-xpad < pos.x < @w + xpad) and (-pad-top < pos.y < @h + pad-bottom)
      @player.body.reset!
      mediator.trigger \falloutofworld

  complete: (status, callback = -> null) ~>
    # If a status object is passed, set 'handled' to true. This is so that if this was triggered by an
    # event, it can know whether or not to wait for callback.
    if status? then status.handled = true

    if @stopped then return

    @stopped = true

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
    @world.remove!
    @player.remove!
    mediator.trigger \levelout
    @stop-listening!
    callback!

  start-editor: ~>
    if $ document.body .has-class \editor then return

    # Put the play back where they started
    <~ @player.body.reset

    # Wait 2 frames so we can ensure that the player has reset before continuing
    <~ mediator.once 'frame:render'
    <~ mediator.once 'frame:render'

    mediator.paused = true

    @renderer.clear-transform!

    editor = new Editor do
      renderer: @renderer
      original-HTML: @conf.html
      original-CSS: @conf.css

    editor-view = new EditorView model: editor, render-el: @renderer.$el, el: $ \#editor
    editor-view.render!
    editor-view.$el.append-to $ \#editor

    @renderer.editor = true
    @renderer.resize!

    @renderer.clear-transform!

    <~ editor.once \save _

    editor-view.restore-entities!
    editor-view.remove!
    @renderer.editor = false
    @renderer.resize!
    @redraw-from (editor.get \html), (editor.get \css)
    mediator.paused = false
