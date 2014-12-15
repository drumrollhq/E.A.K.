require! {
  'game/dom/Mapper'
  'game/editor/Editor'
  'game/editor/EditorView'
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

  hide: ->
    @$el.add-class 'hidden'

  show: ->
    @$el.remove-class 'hidden'

  add-hidden: ->
    @$el.append @conf.hidden.add-class 'entity'

  add-targets: -> targets @el, @conf.targets

  set-HTML-CSS: (html, css) ->
    @current-HTML = html
    @current-CSS = css

    @$el.html html
    @add-hidden!

    @$el.find 'style' .each (i, style) ~>
      $style = $ style
      $style.text! |> @preprocess-css |> $style.text

    css |> @preprocess-css |> @style.text

    @create-map!

  create-map: ~>
    @mapper.build!
    @map = @mapper.map

  preprocess-css: (source) ->
    css = new CSS source
      ..scope \# + @el.id
      ..rewrite-hover '.PLAYER_CONTACT'

    css.to-string!

  start-editor: ->
    console.log 'start editor'
    editor = new Editor {
      renderer: this
      original-HTML: @conf.html
      original-CSS: @conf.css
    }

    editor-view = new EditorView model: editor, render-el: @$el, el: $ '#editor'
      ..render!

    if @level!.tutorial then @tutorial.attach editor-view

  contains: (x, y) ->
    @conf.x < x < @conf.x + @conf.width and @conf.y < y < @conf.y + @conf.height
