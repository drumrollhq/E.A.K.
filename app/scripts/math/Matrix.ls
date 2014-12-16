require! 'math/Vector'

# Basic 2D-matrix class.
# Matrices are in the form:
# ⎡a b⎤
# ⎣c d⎦
module.exports = class Matrix
  (a, b, c, d) ->
    @ <<< {a, b, c, d}
    @from = Vector.pool.alloc!.init a, c
    @to = Vector.pool.alloc!.init b, d

  # Transform a vector by this matrix:
  # ⎡a b⎤⎡x⎤ = ⎡x·a + y·b⎤
  # ⎣c d⎦⎣y⎦   ⎣x·c + y·d⎦
  transform: ({x, y}) ~> Vector.pool.alloc!.init x * @a + y * @b, x * @c + y * @d
