require! {
  './Vector'
  './Matrix'
}

module.exports = prepare = (nodes) ->

  # Map the nodes to their prepared versions.
  nodes = nodes |> map ->
    unless it.prepared
      it.prepared = true

      # Initialize velocity, position, and jump-frames (used to control height of jump)
      it.v = new Vector 0, 0
      it.p = new Vector it.{x, y}
      it.jump-frames = 0

      # pre-calculate basic trig stuff
      it.sin = sint = sin it.rotation
      it.cos = cost = cos it.rotation
      it.matrix = matrix = new Matrix cost, sint, -sint, cost

      # Player stuff:
      if it.data.player then it.data.handle-input = true

      # Find polygon:
      if it.type is 'rect'
        {width, height, x, y} = it
        hw = width / 2
        hh = height / 2
        it.poly = [
          new Vector x - hw, y - hh
          new Vector x + hw, y - hh
          new Vector x + hw, y + hh
          new Vector x - hw, y + hh
        ]

        # If rotated, rotate each point on the polygon accordingly:
        if it.rotation isnt 0
          it.poly = for point in it.poly
            # center on origin:
            c = point .min it.p

            # Apply rotation matrix, translate back to original position
            matrix.transform c .add it.p

    it

  dynamics = nodes |> filter ( -> it.data.player? or it.data.dynamic? )
  nodes = nodes |> filter ( -> not it.data.player? )

  {dynamics, nodes}
