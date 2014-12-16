module.exports = (fn, arr, into = arr) ->
  for item, i in arr => into[i] = fn item
  into
