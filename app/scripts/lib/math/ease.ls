# A set of functions that map values between 0 and 1 to eased values.

export linear = (x) -> x
export sin = (x) -> 0.5 - Math.cos(x * Math.PI) / 2
export lerp = (a, b, x) --> a + x * (b - a)
