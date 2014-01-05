# Simple 2D Vector library.
# Vectors are in the form:
# ⎡x⎤
# ⎣y⎦
module.exports = class Vector
  (x = 0, y = 0) ->
    | typeof x is 'object' => @{x, y} = x.{x, y}
    | otherwise => @ <<< {x, y}

  # Addition, subtraction:
  # ⎡a⎤ + ⎡c⎤ = ⎡a + c⎤
  # ⎣b⎦   ⎣d⎦   ⎣b + d⎦
  add: (v) ~>
    new Vector @x + v.x, @y + v.y

  # [operation]-eq is the equivalent of += in or -= etc. in JS. They modify the Vector instead of returning a new one.
  add-eq: (v) ~>
    @x += v.x
    @y += v.y
    @

  min: (v) ~>
    new Vector @x - v.x, @y - v.y

  min-eq: (v) ~>
    @x -= v.x
    @y -= v.y
    @

  # Distance squared & distance.
  # ⎢⎡a⎤ - ⎡c⎤⎥ = √[ (a - c)² + (b - d)² ]
  # ⎢⎣b⎦   ⎣d⎦⎥
  dist-sq: (v) ~>
    (v.x - @x) * (v.x - @x) + (v.y - @y) * (v.y - @y)

  dist: (v) ~> sqrt @dist-sq v

  # Point in polygon by ray-casting.
  # See http://en.wikipedia.org/wiki/Point_in_polygon
  in-poly: (p) ~>
    {x, y} = @
    c = no
    for i from p.length-1 to 0 by -1
      j = (i+1) % p.length

      if ((((p[i].y <= y) and (y < p[j].y)) or
          ((p[j].y <= y) and (y < p[i].y))) and
          (x < (p[j].x - p[i].x) * (y - p[i].y) / (p[j].y - p[i].y) + p[i].x))

        c = !c

    c
