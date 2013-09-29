Mapper = require "game/dom/Mapper"
CSS = require "game/lang/CSS"

mediator = require "game/mediator"

transform = Modernizr.prefixed "transform"

module.exports = class Renderer extends Backbone.View
  tagName: "div"
  className: "level no-html hidden"
  id: -> "levelrenderer-#{Date.now()}"

  initialize: (options) ->
    @root = options.root
    @$el.appendTo @root

    style = $ "<style></style>"
    style.appendTo document.head
    @$style = style

    @setHTMLCSS options.html, options.css

    @listenTo mediator, "resize", @resize

    @resize()

    @render()

    @mapper = new Mapper @el

    @listenTo mediator, "playermove", @move

  setHTMLCSS: (html, css) =>
    @currentHTML = html
    @currentCSS = css

    @$el.html html

    css = new CSS css
    css.scope "#" + @el.id
    @$style.text css.toString()

  createMap: =>
    @$el.css left: 0, top: 0, marginLeft: 0, marginTop: 0
    @mapper.build()
    @map = @mapper.map
    @resize()
    @map

  render: =>
    # Not a brilliant name, considering it only makes already-rendered stuff
    # visible
    @$el.removeClass "hidden"

  remove: (done = ->) =>
    @$el.addClass "hidden"
    ($ document.body).removeClass "playing"
    setTimeout =>
      @$style.remove()
      super
      done()
    , 1000

  resize: =>
    elWidth = @$el.width()
    elHeight = @$el.height()
    winWidth = @$window.width()
    winHeight = @$window.height()

    @width = elWidth
    @height = elHeight

    if @editor is true then winWidth = winWidth / 2

    scrolling =
      x: no
      y: no

    if @lastPosition is undefined then @lastPosition = x: 0, y: 0

    if winWidth < elWidth
      scrolling.x = winWidth
      @$el.css left: 0, marginLeft: ''
    else
      @$el.css left: "50%", marginLeft: -elWidth/2

    if winHeight < elHeight
      scrolling.y = winHeight
      @$el.css top: 0, marginTop: ''
    else
      @$el.css top: "50%", marginTop: -elHeight/2

    @scrolling = scrolling

  setWidth: (width) =>
    @$el.width width
    @resize()

  setHeight: (height) =>
    @$el.height height
    @resize()

  pad = 30
  damping = 10

  move: (position) =>
    lx = @lastPosition.x
    ly = @lastPosition.y

    tx = lx + (position.x - lx) / damping
    ty = ly + (position.y - ly) / damping

    @lastPosition = x: tx, y: ty

    @moveDirect x: tx, y: ty

  moveDirect: (position, scroll = false) =>
    s = @scrolling
    w = @width
    h = @height

    if s.x isnt false
      max = (w + 2*pad) - s.x
      tx = max * (position.x / w) - pad
    else
      tx = 0

    if s.y isnt false
      max = (h + 2*pad) - s.y
      ty = max * (position.y / h) - pad
    else
      ty = 0

    @el.style[transform] = if tx is 0 and ty is 0 then "" else "translate3d(#{-tx}px, #{-ty}px, 0)"

  $window: $ window
