require! {
  'game/dom/Mapper'
  'game/lang/CSS'
  'game/mediator'
}

transform = Modernizr.prefixed \transform

const offset-top = 50

module.exports = class Renderer extends Backbone.View
  tag-name: \div
  class-name: 'level no-html hidden'
  hover-class: 'PLAYER_CONTACT'

  id: -> "levelrenderer-#{Date.now!}"

  initialize: (options) ->
    @{root} = options
    @$el.append-to @root

    style = $ '<style></style>'
    style.append-to document.head
    @$style = style

    @set-HTML-CSS options.html, options.css

    @listen-to mediator, \resize @resize

    @resize!
    @render!
    @mapper = new Mapper @el

    @listen-to mediator, \playermove @move
    @setup-hover!

  set-HTML-CSS: (html, css) ~>
    @current-HTML = html
    @current-CSS = css

    @$el.html html

    @$el.find 'style' .each (i, style) ~>
      $style = $ style
      console.log $style.text!
      $style |> ( .text! ) |> @preprocess-css |> $style.text
      console.log $style.text!

    css |> @preprocess-css |> @$style.text

  preprocess-css: (source) ~>
    css = new CSS source
    css
      ..scope \# + @el.id
      ..rewrite-hover '.' + Renderer::hover-class
      ..to-string!

  create-map: ~>
    @clear-transform!
    @$el.css left: 0, top: 0, margin-left: 0, margin-top: 0
    @mapper.build!
    @map = @mapper.map
    @resize!
    @map

  setup-hover: ~>
    @listen-to mediator, 'beginContact:*&ENTITY_PLAYER' (collision) ~>
      if el = collision.a.def.el
        el.class-list.add Renderer::hover-class
        el.trigger-fake-transition-start! if el.trigger-fake-transition-start?

    @listen-to mediator, 'endContact:*&ENTITY_PLAYER' (collision) ~>
      if el = collision.a.def.el
        el.class-list.remove Renderer::hover-class
        el.trigger-fake-transition-start! if el.trigger-fake-transition-start?

  append: ~> @$el.append it

  render: ~>
    # Not a brilliant name, considering it only makes already-rendered stuff
    # visible
    @$el.remove-class \hidden

  remove: (done = ->) ~>
    @$el.add-class \hidden
    $ document.body .remove-class \playing
    <~ set-timeout _, 500
    @$style.remove!
    super!
    done!

  resize: ~>
    el-width = @width = @$el.width!
    el-height = @height = @$el.height!
    win-width = @$window.width!
    win-height = @$window.height! - offset-top

    console.log win-width, win-height

    if @editor then win-width = win-width / 2

    scrolling = x: no, y: no

    unless @last-position? => @last-position = x: 0, y: 0

    if win-width < el-width
      scrolling.x = win-width
      @$el.css left: 0, margin-left: ''
    else
      @$el.css left: '50%', margin-left: -el-width / 2

    if win-height < el-height
      scrolling.y = win-height - offset-top
      @$el.css top: 0, margin-top: offset-top
    else
      @$el.css top: '50%', margin-top: (offset-top - el-height) / 2

    @scrolling = scrolling

  set-width: (width) ~>
    @$el.width width
    @resize!

  set-height: (height) ~>
    @$el.height height
    @resize!

  const pad = 30
  const damping = 10

  move: (position) ~>
    l = @last-position.{x, y}

    position.y -= offset-top

    t =
      x: l.x + (position.x - l.x) / damping
      y: l.y + (position.y - l.y) / damping

    @last-position = t.{x, y}

    @move-direct t.{x, y}

  move-direct: (position, scroll = false) ~>
    s = @scrolling
    w = @width
    h = @height

    # console.log 'x: ', position.x, 'y: ', position.y, 'sx: ', s.x, 'sy: ', s.y, w, h

    t =
      x: if s.x then ((w + 2*pad) - s.x) * (position.x / w) - pad else 0
      y: if s.y then ((h + 2*pad) - s.y) * (position.y / h) - pad else 0

    @el.style[transform] = if t.x is 0 and t.y is 0 then '' else "translate3d(#{-t.x}px, #{-t.y}px, 0)"

  clear-transform: ~>
    @el.style[transform] = 'translate3d(0, 0, 0)'
    @last-position = x: 0, y: 0

  $window: $ window
