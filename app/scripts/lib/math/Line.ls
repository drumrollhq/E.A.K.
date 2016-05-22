require! {
  'lib/math/Vector'
}

lerp = (a, b, n) --> a + n * (b - a)
lerp-vec = (a, b, n) --> new Vector (a.x + n * (b.x - a.x)), (a.y + n * (b.y - a.y))

module.exports = class Line
  (@a, @b) ->
    @length = @a.dist @b
    @lerp = lerp-vec @a, @b

  at: (dist) -> @lerp dist / @length
