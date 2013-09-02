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

      c =
        x: (bounds.left + bounds.right) / 2
        y: (bounds.top + bounds.bottom) / 2

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
            # Perfect Circle
            obj =
              type: "circle"
              x: c.x
              y: c.y
              radius: bounds.width / 2

          else if (bounds.width > bounds.height) and (bounds.height is r*2)
            # Landscape Pill
            w = bounds.width - r*2
            obj =
              type: "compound"
              x: c.x
              y: c.y
              shapes: [
                type: "rect"
                x: 0
                y: 0
                width: w
                height: bounds.height
              ,
                type: "circle"
                x: -w/2
                y: 0
                radius: r
              ,
                type: "circle"
                x: w/2
                y: 0
                radius: r
              ]

          else if (bounds.height > bounds.width) and (bounds.width is r*2)
            # Portrait Pill
            h = bounds.height - r*2
            obj =
              type: "compound"
              x: c.x
              y: c.y
              shapes: [
                type: "rect"
                x: 0
                y: 0
                width: bounds.width
                height: h
              ,
                type: "circle"
                x: 0
                y: -h/2
                radius: r
              ,
                type: "circle"
                x: 0
                y: h/2
                radius: r
              ]

        else
          console.log "Err: Not uniform"
          console.log (_.clone bounds), (_.clone style)

      else
        obj =
          type: "rect"
          x: c.x
          y: c.y
          width: bounds.width
          height: bounds.height

      obj.el = node

      data = {}
      for attribute in node.attributes
        name = attribute.name
        if (m = name.match /^data-[a-z1-9\-]+/) isnt null
          data[m[0].replace /^data-/, ""] = attribute.value

      obj.data = data

      if data.ignore is undefined then map.push obj

    @map = map
