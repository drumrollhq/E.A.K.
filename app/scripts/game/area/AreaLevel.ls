require! {
  'assets'
  'game/actors'
  'game/area/el-modify'
  'game/area/settings'
  'game/editor/Editor'
  'game/editor/EditorView'
  'game/editor/tutorial/Tutorial'
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

module.exports = class AreaLevel extends Backbone.View
  class-name: 'area-level'
  id: -> _.unique-id 'arealevel-'

  initialize: ({@level, @prefix}) ->
    @mapper = new Mapper @el

  load: ~>
    src = assets.load-asset "#{@prefix}/areas/#{@level.url}"
    [err, $level] = parse-src src, @level
    if err then throw err
    @level.src = src
    @level.$el = $level
    @conf = conf = settings.find @level.$el
    conf <<< @level.{x, y}

    if conf.has-tutorial
      @tutorial = new Tutorial conf.tutorial

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
    # @tutorial?.remove!
    super!

  activate: ->
    @hint-controller ?= new HintController hints: @conf.hints, scope: @$el, store: @level-store
    @hint-controller.activate!

  deactivate: ->
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
      actors.from-el actor-el, @conf.{x, y}, @level-store, @area-view

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

  set-error: (error) ->
    if error?
      @$el.add-class 'has-errors'
    else
      @$el.remove-class 'has-errors'

  create-map: (offset-top, offset-left) ~>
    el-modify @$el
    @mapper.build offset-top, offset-left
    @map = @mapper.map
    @add-borders @map
    @map = @map ++ @actors
    @map

  preprocess-css: (source) ->
    css = new CSS source
      ..scope \# + @el.id
      ..rewrite-hover '.PLAYER_CONTACT'
      ..rewrite-assets (url) ->
        if url.match /^(\/\/|https?:|blob:)/ then url else assets.load-asset url, \url

    css.to-string!

  start-editor: ->
    if @conf.has-tutorial then $ document.body .add-class 'has-tutorial'
    editor = new Editor {
      renderer: this
      original-HTML: @conf.html
      original-CSS: @conf.css
    }

    editor-view = new EditorView model: editor, render-el: @$el, el: $ '#editor'
      ..render!

    if @tutorial then @tutorial.attach editor-view

    editor.once \save, ~> @stop-editor editor, editor-view

  stop-editor: (editor, editor-view) ->
    if @tutorial then @tutorial.detach!
    $ document.body .remove-class 'has-tutorial'
    editor-view.restore-entities!
    editor-view.remove!
    @level-store.patch-state code: html: editor.get \html
    @redraw-from (editor.get \html), (editor.get \css)

    channels.game-commands.publish command: \stop-edit

  contains: (x, y) ->
    @conf.x < x < @conf.x + @conf.width and @conf.y < y < @conf.y + @conf.height

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
