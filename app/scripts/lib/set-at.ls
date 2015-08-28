module.exports = set-at = (obj, path, val, {sep = '.', overwrite = true} = {}) ->
  | typeof path is \string => set-at obj, (path.split sep), val, sep
  | path.length is 1 and overwrite => obj[first path] = val
  | path.length is 1 and not overwrite => obj[first path] ?= val
  | otherwise => set-at obj{}[first path], (tail path), val, sep
