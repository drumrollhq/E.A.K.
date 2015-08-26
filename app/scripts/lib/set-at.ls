module.exports = set-at = (obj, path, val, sep = '.') ->
  | typeof path is \string => set-at obj, (path.split sep), val, sep
  | path.length is 1 => obj[first path] = val
  | otherwise => set-at obj{}[first path], (tail path), val, sep
