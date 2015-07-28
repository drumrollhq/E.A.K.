require! {
  'lib/math/Vector'
}

lerp = (a, b, n) -> a + n * (b - a)

module.exports = class Bezier
  (@a, @d, @b, @c, @resolution = 512) ->
    d = 1 / @resolution

    last-x = @interpolate-x 0
    last-y = @interpolate-y 0
    length = 0
    for i from d to 1 by d
      x = @interpolate-x i
      y = @interpolate-y i
      length += Math.sqrt (last-x - x) * (last-x - x) + (last-y - y) * (last-y - y)
      last-x = x
      last-y = y

    @length = length

  interpolate-x: (n) ->
    a1x = lerp @a.x, @b.x, n
    b1x = lerp @b.x, @c.x, n
    c1x = lerp @c.x, @d.x, n
    a2x = lerp a1x, b1x, n
    b2x = lerp b1x, c1x, n
    lerp a2x, b2x, n

  interpolate-y: (n) ->
    a1y = lerp @a.y, @b.y, n
    b1y = lerp @b.y, @c.y, n
    c1y = lerp @c.y, @d.y, n
    a2y = lerp a1y, b1y, n
    b2y = lerp b1y, c1y, n
    lerp a2y, b2y, n

  interpolate: (n) ->
    new Vector (@interpolate-x n), (@interpolate-y n)

  at: (n) ->
    @interpolate n / @length
