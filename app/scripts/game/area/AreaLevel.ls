require! {
  'channels'
  'game/dom/Mapper'
  'game/editor/Editor'
  'game/editor/EditorView'
  'game/hints/HintController'
  'game/lang/CSS'
  'game/level/settings'
  'game/targets'
}

counter = 0

create-style = ->
  $ '<style></style>'
    ..append-to document.head

module.exports = class AreaLevel extends Backbone.View
  class-name: 'area-level'
  id: -> "arealevel-#{counter++}-#{Date.now!}"

  initialize: (level) ->
    @level = level
    conf = @conf = settings.find level.$el
    conf <<< level.{x, y}

    @mapper = new Mapper @el

    @style = create-style!
    @set-HTML-CSS conf.html, conf.css

  render: ->
    @$el.css {
      width: @conf.width
      height: @conf.height
      top: @conf.y
      left: @conf.x
    }

  activate: ->
    @hint-controller ?= new HintController hints: @conf.hints, scope: @$el

  hide: ->
    @$el.add-class 'hidden'

  show: ->
    @$el.remove-class 'hidden'

  add-hidden: ->
    @$el.append @conf.hidden.add-class 'entity'

  add-targets: -> targets @el, @conf.targets

  redraw-from: (html, css) ->
    entities = @$el.children '.entity' .detach!
    @set-HTML-CSS html, css
    entities.append-to @$el

  set-HTML-CSS: (html, css) ->
    @current-HTML = html
    @current-CSS = css

    @$el.html html
    @add-hidden!

    @$el.find 'style' .each (i, style) ~>
      $style = $ style
      $style.text! |> @preprocess-css |> $style.text

    css |> @preprocess-css |> @style.text

  create-map: ~>
    @mapper.build!
    @map = @mapper.map

  preprocess-css: (source) ->
    css = new CSS source
      ..scope \# + @el.id
      ..rewrite-hover '.PLAYER_CONTACT'

    css.to-string!

  start-editor: ->
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
    editor-view.restore-entities!
    editor-view.remove!
    @redraw-from (editor.get \html), (editor.get \css)

    @trigger 'stop-editor'

  contains: (x, y) ->
    @conf.x < x < @conf.x + @conf.width and @conf.y < y < @conf.y + @conf.height
