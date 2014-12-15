require! 'math/Vector'

# Basic 2D-matrix class.
# Matrices are in the form:
# ⎡a b⎤
# ⎣c d⎦
module.exports = class Matrix
  (a, b, c, d) ->
    @ <<< {a, b, c, d}
    @from = new Vector a, c
    @to = new Vector b, d

  # Transform a vector by this matrix:
  # ⎡a b⎤⎡x⎤ = ⎡x·a + y·b⎤
  # ⎣c d⎦⎣y⎦   ⎣x·c + y·d⎦
  # ALLOC
  transform: ({x, y}) ~> new Vector x * @a + y * @b, x * @c + y * @d
