module.exports = class Mapper
  constructor: (@el) ->

  normaliseStyle: (css) ->
    css = _.clone css

    # border-radius
    br1 = br2 = ""
    for corner in ["TopLeft", "TopRight", "BottomRight", "BottomLeft"]
      br = css["border#{corner}Radius"].split " "
      if br.length is 1
        br1 += br[0]
        br2 += br[0]
      else
        br1 += br[0]
        br2 += br[1]

      br1 += " "
      br2 += " "

    css.borderRadius = "#{br1.trim()} / #{br2.trim()}"

    css

  build: ->
    window.scrollTo 0, 0

    map = []
    nodes = @el.children

    for node in nodes
      bounds = node.getBoundingClientRect()
      style = @normaliseStyle window.getComputedStyle node

      if style.borderRadius isnt "0px 0px 0px 0px / 0px 0px 0px 0px"
        br = style.borderRadius.replace("/ ", "").split " "
        uniform = yes

        last = br[0]
        for r in br
          if r isnt last
            uniform = no

        if uniform
          r = parseFloat(br[0])

          if (bounds.width is bounds.height) and (r >= bounds.width / 2) and (r >= bounds.height / 2)
            obj =
              type: "circle"
              x: bounds.left + bounds.width / 2
              y: bounds.top + bounds.height / 2
              radius: bounds.width / 2

      else
        obj =
          type: 'rect'
          x: bounds.left + bounds.width / 2
          y: bounds.top + bounds.height / 2
          width: bounds.width / 2
          height: bounds.height / 2

      obj.el = node

      map.push obj

    @map = map
