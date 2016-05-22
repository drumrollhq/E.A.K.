require! {
  'lib/math/ease'
  'lib/math/Line'
  'lib/math/Vector'
}

lerp = (a, b, n) --> a + n * (b - a)
lerp-vec = (a, b, n) --> new Vector (a.x + n * (b.x - a.x)), (a.y + n * (b.y - a.y))

module.exports = class Path
  (points, @alternate = false, @ease = 'linear') ->
    if points.length < 2 then throw new Error 'Path must have at least 2 points!'

    @points = points
    @lines = @get-lines!

  point: (n) -> @points[n]
  line: (n) -> @lines[n]

  get-lines: ->
    lines = []
    last = @points.0
    for i from 1 til @points.length
      point = @points[i]
      lines[*] = new Line last, point
      last = point

    lines

  length: -> @_length or @calc-length!
  calc-length: -> sum @lengths!

  lengths: -> @_lengths or @calc-lengths!
  calc-lengths: -> @lines |> map ( .length )

  at: (dist, prevent-recursion = false) ->
    length = @length!
    if prevent-recursion or 0 <= dist <= length
      dist = length * (ease[@ease] dist / length)
      so-far = 0
      i = 0
      while so-far < dist, i++
        line = @lines[i]
        so-far += line.length

      line ?= @lines[@lines.length - 1]
      line.at dist - (so-far - line.length)
    else
      if @alternate # At end, alternate
        @at length - (abs (abs dist) % (2 * length) - length), true
      else # At end, revese
        @at dist - length * (floor dist / length), true
