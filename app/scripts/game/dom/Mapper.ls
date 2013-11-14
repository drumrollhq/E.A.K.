# Mapper is used for retrieving a description/map of the shapes of nodes in a
# DOM element. We feed it the level element, and it spits out a list of shapes
# we can use in the physics engine.
#
# TODO:
# - Support CSS transforms
# - Support CSS animations
# - Support weird combinations of border-radius

module.exports = class Mapper
  (@el) ->

  # normalise-style is used to make sure that style objects are consistent
  # across browsers.
  normalise-style: (css) ->
    # stuff from get-computed-style is immutable, so we clone it
    css = _.clone css

    # Currently, this function deals mainly with border-radius related issues.
    # The border-radius value doesn't have a consistent value across values, so
    # we assemble one from the individual corners
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

  # Build is the main function we expose. It returns the map, and sets this.map
  # to the map.
  build: ->
    # Measurements are relative to the position in the window, not the document
    window.scroll-to 0, 0

    # Make sure we don't get errors due to offset
    offset = @el.get-bounding-client-rect!.{top, left}

    map = []
    nodes = @el.children

    for node in nodes
      # Fetch measurements from the browser
      bounds = node.get-bounding-client-rect!
      style = node |> window.get-computed-style |> @normalise-style

      # Find the center of the element
      c =
        x: ((bounds.left + bounds.right) / 2) - offset.left
        y: ((bounds.top + bounds.bottom) / 2) - offset.top

      if style.border-radius isnt "0px 0px 0px 0px / 0px 0px 0px 0px"
        # There are some rounded corners
        br = style.border-radius.replace '/ ' '' .split ' '

        # Check if borders are all the same or not
        uniform = yes

        last = br.0
        for r in br => if r isnt last then uniform = false

        # If all the borders are uniform
        if uniform
          # Find radius
          r = parse-float br.0

          # Calculate inner width and height
          w = bounds.width - r * 2
          h = bounds.height - r * 2

          if bounds.width is bounds.height and r >= bounds.width / 2
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
              shapes: [
              * type: \rect
                x: 0
                y: 0
                width: bounds.width
                height: h

              * type: \circle
                x: 0
                y: -h / 2
                radius: r

              * type: \circle
                x: 0
                y: h / 2
                radius: r
              ]

          else
            # Uniform rounded rect
            obj =
              type: \compound
              x: c.x
              y: c.y
              shapes: [
              * type: \rect
                x: 0
                y: 0
                width: bounds.width
                height: h

              * type: \rect
                x: 0
                y: 0
                width: bounds.width
                height: h

              * type: \circle
                x: w/2
                y: h/2
                radius: r

              * type: \circle
                x: -w/2
                y: h/2
                radius: r

              * type: \circle
                x: -w/2
                y: -h/2
                radius: r

              * type: \circle
                x: w/2
                y: -h/2
                radius: r
              ]

        else
          # TODO
          console.log 'Err: not uniform'
          console.log (_.clone bounds), _.clone style

      else
        # Rectangles are easy.
        obj =
          type: \rect
          x: c.x
          y: c.y
          width: bounds.width
          height: bounds.height

      # Save the node we're measuring with the outputted object
      obj.el = node

      # Pull out all the data-* attributes, and add them to a data object on obj
      data = {}
      for attribute in node.attributes
        name = attribute.name
        if (m = name.match /^data-[a-z1-9\-]+/) isnt null
          data[m.0.replace /^data-/, ''] = attribute.value

      obj.data = data

      # Check that there's no data-ignore attribute - if there is, don't add
      # this object to the map.
      if data.ignore is undefined then map.push obj

    @map = map
