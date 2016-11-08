require! {
  'assets'
  'game/actors'
  'game/area/el-modify'
  'game/area/settings'
  'game/editor/Editor'
  'game/editor/EditorView'
  'game/editor/Tutorial'
  'game/effects/SpriteSheet'
  'game/hints/HintController'
  'lib/channels'
  'lib/dom/Mapper'
  'lib/lang/CSS'
  'lib/lang/html'
  'translations'
}

counter = 0

create-style = ->
  $ '<style></style>'
    ..append-to document.head

level-scripts = {}

module.exports = class AreaLevel extends Backbone.View
  class-name: 'area-level'
  id: -> _.unique-id 'arealevel-'

  initialize: ({@level, @prefix}) ->
    level-scripts[@level.url] ?= []
    @mapper = new Mapper @el
    @hook \initialize

  load: ~>
    src = assets.load-asset "#{@prefix}/areas/#{@level.url}"
    [err, $level] = parse-src src, @level
    if err then throw err
    @level.src = src
    @level.$el = $level
    @conf = conf = settings.find @level.$el
    conf <<< @level.{x, y}

    @hook \load
    this

  setup: (stage, @area-view) ~>
    @stage-store = stage
    @level-store = stage.scope-level @level.url
    @$el.css {
      position: \absolute
      left: @conf.x
      top: @conf.y
      width: @conf.width
      height: @conf.height
    }

    @tutorial = new Tutorial!
    @hook \tutorial, @tutorial

    @targets-to-actors!
    @style = create-style!
    html = @level-store.get \state.code.html or @conf.html
    @set-HTML-CSS html, @conf.css
    @add-actors!
    Promise.all @actors.map ( .load! )

  setup-sprite-sheets: ->
    Promise
      .map (@$ '[data-sprite]').to-array!, (el) ~>
        sprite = SpriteSheet.from-el el, @conf.x, @conf.y
        layer = $ el .attr \data-layer or \effects
        sprite.load! .then -> [sprite, layer]
      .tap (sprites) ~> @sprites = sprites

  render: ->
    @$el.css {
      width: @conf.width
      height: @conf.height
      top: @conf.y
      left: @conf.x
    }

  remove: ->
    @hint-controller?.destroy!
    @style.remove!
    for sprite in @sprites => sprite.0.remove!
    for actor in @actors => actor.remove!
    @hook \cleanup
    # @tutorial?.remove!
    super!

  activate: ->
    @hook \activate
    @hint-controller ?= new HintController hints: @conf.hints, scope: @$el, store: @level-store
    @hint-controller.activate!

  deactivate: ->
    @hook \deactivate
    if @hint-controller then @hint-controller.deactivate!

  hide: ->
    @$el.add-class 'hidden'

  show: ->
    @$el.remove-class 'hidden'

  focus: ->
    @$el.add-class \focused

  unfocus: ->
    @$el.remove-class \focused

  add-hidden: ->
    @$el.append @conf.hidden.add-class 'entity'

  targets-to-actors: ->
    targets = @conf.targets
      .map ({x, y}, i) ~> {x, y, id: "#{@level.url.replace /[^a-zA-Z0-9]/g ''}##{i}"}
      |> reject ({id}) ~> (@level-store.get 'state.kittens' or {})[id]
      |> map (target) ~>
        $ """
          <div class="entity-target" data-actor="kitten-box #{target.x} #{target.y} #{target.id}"></div>
        """

    for target in targets => @conf.hidden .= add target

  add-actors: ->
    @actors ?= for actor-el in @$ '[data-actor]'
      actors.from-el actor-el, @conf.{x, y}, @level-store, @area-view, this

  add-borders: (nodes) ->
    const thickness = 30px
    {width, height, x, y, borders, border-contract} = @conf

    if \top in borders
      nodes[*] = {
        type: \rect, id: \BORDER_TOP
        width: width, height: thickness
        x: x + width/2, y: y - thickness/2 + border-contract
      }

    if \left in borders
      nodes[*] = {
        type: \rect, id: \BORDER_LEFT
        width: thickness, height: height
        x: x - thickness/2 + border-contract, y: y + height/2
      }

    if \bottom in borders
      nodes[*] = {
        type: \rect, id: \BORDER_BOTTOM
        width: width, height: thickness
        x: x + width/2, y: y + height + thickness/2 - border-contract
      }

    if \right in borders
      nodes[*] = {
        type: \rect, id: \BORDER_RIGHT
        width: thickness, height: height
        x: x + width + thickness/2 - border-contract, y: y + height/2
      }

  redraw-from: (html, css) ->
    entities = @$el.children '.entity' .detach!
    @set-HTML-CSS html, css
    entities.append-to @$el

  set-HTML-CSS: (html-src, css-src) ->
    @current-HTML = html-src
    @current-CSS = css-src

    parsed = html.to-dom html-src
    @$el.empty!.append parsed.document
    @add-hidden!

    @$el.find 'style' .each (i, style) ~>
      $style = $ style
      $style.text! |> @preprocess-css |> $style.text

    css-src |> @preprocess-css |> @style.text

    @set-error parsed.error
    @hook \setHtmlCss

  redraw: ->
    @redraw-from @current-HTML, @current-CSS

  set-error: (error) ->
    if error?
      @has-errors = true
      @$el.add-class 'has-errors'
    else
      @has-errors = false
      @$el.remove-class 'has-errors'

    channels.triggers.publish id: \error-change

  create-map: (offset-top, offset-left) ~>
    el-modify @$el
    @mapper.build offset-top, offset-left
    @map = @mapper.map
    @add-borders @map
    @map = @map ++ @actors
    @hook \map
    @map

  preprocess-css: (source) ->
    css = new CSS source
      ..scope \# + @el.id
      ..rewrite-hover '.PLAYER_CONTACT'
      ..rewrite-assets (url) ->
        if url.match /^(\/\/|https?:|blob:)/ then url else assets.load-asset url, \url

    css.to-string!

  start-editor: ->
    @editor = editor = new Editor {
      renderer: this
      original-HTML: @conf.html
      original-CSS: @conf.css
    }

    @editor-view = editor-view = new EditorView {
      model: editor
      render-el: @$el
      el: $ '#editor'
      tutorial: @tutorial
    }

    editor.once \save, ~> @stop-editor editor, editor-view
    @hook \edit, editor, editor-view
    @tutorial.start!

  stop-editor: (editor, editor-view) ->
    if @tutorial then @tutorial.stop!
    editor-view.restore-entities!
    editor-view.remove!
    @level-store.patch-state code: html: editor.get \html
    @redraw-from (editor.get \html), (editor.get \css)

    channels.game-commands.publish command: \stop-edit
    @hook \stopEdit

  contains: (x, y) ->
    @conf.x < x < @conf.x + @conf.width and @conf.y < y < @conf.y + @conf.height

  editable: ->
    editable = @hook-sync \editable
    if editable? then editable else @conf.editable

  _hook: (name, ...args) ->
    hooks = level-scripts[@level.url]
      |> filter (script) ~> script[name]
      |> map (script) ~> script[name].apply this, args

  hook-sync: (name, ...args) ->
    @_hook name, ...args
      |> filter (it) -> it?
      |> first

  hook: (name, ...args) ->
    Promise.all @_hook name, ...args

  has-hook: (name) ->
    hooks = level-scripts[@level.url]
    for hook in hooks when typeof hook[name] is \function => return true
    return false

  @register-level-script = (url, script) ->
    hooks = keys script
    console.log "[area-level] Register #{hooks.join ', '} hooks for #url"
    level-scripts[url] ?= []
    level-scripts[url][*] = script
    script.deregister = ->
      console.log "[area-level] Register #{hooks.join ', '} hooks for #url"
      level-scripts[name] .= filter (isnt script)

    script

parse-src = (src, level) ->
  parsed = html.to-dom src

  if parsed.error
    unless parsed.document.query-selector 'meta[name=glitch]'
      console.log src, parsed.error
      channels.alert.publish msg: translations.errors.level-errors + "[#{level.url}]"
      return [parsed.error]

  for node in parsed.document.child-nodes
    if typeof! node is 'HTMLHtmlElement' then $level = $ node

  $level.source = src
  el-modify $level

  return [null, $level]
