module.exports = (char, len, str) -->
  str += '' # ensure str is a string
  if str.length < len
    for i from 0 til len - str.length => str = char + str
    str
  else str
