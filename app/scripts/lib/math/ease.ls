# A set of functions that map values between 0 and 1 to eased values.

export linear = (x) -> x
export sin = (x) -> 0.5 - Math.cos(x * Math.PI) / 2
export sin-arch = (x) -> Math.sin x * Math.PI
export sin-arch-midpoint = (x, midpoint) ->
  if x < midpoint
    Math.sin (Math.PI/2) * (x/midpoint)
  else
    Math.sin ((x + 1 - midpoint/2) / (1 - midpoint)) * Math.PI/2

export lerp = (a, b, x) --> a + x * (b - a)
