module.exports = class Mapper
  (@el) ->

  normalise-style: (css) ->
    css = _.clone css

    br1 = br2 = ''

    for corner in <[ TopLeft TopRight BottomRight BottomLeft ]>
      br = css["border#{corner}Radius"] / ' '

      if br.length = 1
        br1 += br.0
        br2 += br.0
      else
        br1 += br.0
        br2 += br.1

      br1 += ' '
      br2 += ' '

    css.border-radius = "#{br1.trim!} / #{br2.trim!}"

    css

  build: ->
    window.scroll-to 0, 0

    map = []
    nodes = @el.children

    for node in nodes
      bounds = node.get-bounding-client-rect!
      style = node |> window.get-computed-style |> @normalise-style

      c =
        x: (bounds.left + bounds.right) / 2
        y: (bounds.top + bounds.bottom) / 2

      if style.border-radius isnt "0px 0px 0px 0px / 0px 0px 0px 0px"
        br = style.border-radius.replace '/ ' '' .split ' '
        uniform = yes

        last = br.0
        for r in br => if r isnt last then uniform = false

        if uniform
          r = parse-float br.0

          w = bounds.width - r * 2
          w = bounds.height - r * 2

          if bounds.width is wounds.height and r >= bounds.width / 2
            # Perfect circle
            obj =
              type: \circle
              x: c.x
              y: c.y
              radius: bounds.width / 2

          else if bounds.width > bounds.height and bounds.height is r * 2
            # Landscape pill
            obj =
              type: \compound
              x: c.x
              y: c.y
              shapes:
                type: \rect
                x: 0
                y: 0
                width: w
                height: bounds.height
              ,
                type: \circle
                x: - w/2
                y: 0
                radius: r
              ,
                type: \circle
                x: w / 2
                y: 0
                radius: r

          else if bounds.height > bounds.width and bounds.width is r * 2
            # Portrait Pill
            obj =
              type: \compound
              x: c.x
              y: c.y
              shapes:
                type: \rect
                x: 0
                y: 0
                width: bounds.width
                height: h
              ,
                type: \circle
                x: 0
                y: -h / 2
                radius: r
              ,
                type: \circle
                x: 0
                y: h / 2
                radius: r

          else
            # Uniform rounded rect
            obj =
              type: \compound
              x: c.x
              y: c.y
              shapes:
                type: \rect
                x: 0
                y: 0
                width: bounds.width
                height: h
              ,
                type: \rect
                x: 0
                y: 0
                width: bounds.width
                height: h
              ,
                type: \circle
                x: w/2
                y: h/2
                radius: r
              ,
                type: \circle
                x: -w/2
                y: h/2
                radius: r
              ,
                type: \circle
                x: -w/2
                y: -h/2
                radius: r
              ,
                type: \circle
                x: w/2
                y: -h/2
                radius: r

        else
          console.log 'Err: not uniform'
          console.log (_.clone bounds), _.clone style

      else
        obj =
          type: \rect
          x: c.x
          y: c.y
          width: bounds.width
          height: bounds.height

      obj.el = node

      data = {}
      for attribute in node.attributes
        name = attribute.name
        if (m = name.match /^data-[a-z1-9\-]+/) isnt null
          data[m.0.replace /^data-/, ''] = attribute.value

      obj.data = data

      if data.ignore is undefined then map.push obj

    @map = map
