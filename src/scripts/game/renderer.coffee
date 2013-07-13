Mapper = require "game/dom/mapper"

mediator = require "game/mediator"

module.exports = class Renderer extends Backbone.View
  tagName: "div"
  className: "level no-html hidden"
  id: -> "levelrenderer-#{Date.now()}"

  initialize: (options) ->
    @$el.html options.html
    @$el.appendTo document.body

    css = @scopeCSS "#"+@el.id, options.css
    style = $ "<style></style>"
    style.text css
    style.appendTo document.head
    @$style = style

    ($ document.body).addClass "playing"

    @listenTo mediator, "resize", @resize

    @resize()

    @render()

    @mapper = new Mapper @el

  map: =>
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
    , 400

  resize: =>
    elWidth = @$el.width()
    elHeight = @$el.height()
    winWidth = @$window.width()
    winHeight = @$window.height()

    @width = elWidth
    @height = elHeight

    scrolling =
      x: no
      y: no

    if winWidth < elWidth
      scrolling.x = yes
      @$el.css left: 0, marginLeft: 0
    else
      @$el.css left: "50%", marginLeft: -elWidth/2

    if winHeight < elHeight
      scrolling.y = yes
      @$el.css top: 0, marginTop: 0
    else
      @$el.css top: "50%", marginTop: -elHeight/2

    mediator.trigger "renderer:set:scrolling", scrolling

  setWidth: (width) =>
    @$el.width width
    @resize()

  setHeight: (height) =>
    @$el.height height
    @resize()

  scopeCSS: (scope, css) ->
    ###
    This is a little and very simple CSS parser. It goes through the text and
    identifies selectors (ignoring @media or @keyframe or similar) and adds
    scope to the start of the selector, so the declarations only apply to
    elements within scope.

    FIXME: Currently breaks on @keyframe "from", "to", and "x%" as these look
    very similar to normal selectors.
    ###

    # First off, strip comments:
    css = css.replace /\/\*[\s\S]+?\*\//gm, ""

    currentSelector = ""
    currentDeclaration = ""
    inDeclaration = no
    inSelector = no
    ignoreCurrentSelector = no

    out = ""

    for c in css
      # Copy the contents of the declaration pretty much straight to output
      if inDeclaration
        switch c
          when "}"
            out += "{ \n#{currentDeclaration} \n}\n"
            inDeclaration = no

          else
            currentDeclaration += c

      # Skip over @ selectors, copying them directly to output
      else if ignoreCurrentSelector
        switch c
          when "{"
            ignoreCurrentSelector = no
            inSelector = no
            inDeclaration = no
            currentDeclaration = ""
            out += "{\n"

          else
            out += c

      else
        if inSelector
          # Grab selectors then modify their content
          switch c
            when ",", "{"
              # End of selector -
              currentSelector = "#{scope} #{currentSelector}"
              out += " #{currentSelector} "
              if c is "," then out += "," else inDeclaration = yes
              inSelector = no
              currentDeclaration = ""

            else
              currentSelector += c

        else
          # Look out for things that indicate the start of a new selector
          switch c
            when " ", "\n"
              # pass
              undefined

            when "}"
              # probably left over from an @ keyword
              out += "\n}\n"

            when "@"
              inSelector = yes
              ignoreCurrentSelector = yes
              out += c

            else
              inSelector = yes
              ignoreCurrentSelector = no
              currentSelector = c

    out

  $window: $ window