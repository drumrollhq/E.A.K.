module.exports = set-at = (obj, path, val) -->
  | typeof path is \string => set-at obj, (path.split '.'), val
  | path.length is 1 => obj[first path] = val
  | otherwise => set-at obj{}[first path], (tail path), val
