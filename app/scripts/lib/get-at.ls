module.exports = get-at = (obj, path, sep = '.') ->
  | typeof! obj not in <[Object Array]> => void
  | typeof path is \string => get-at obj, (path.split sep), sep
  | path.length is 1 => obj[first path]
  | path.length is 0 => obj
  | otherwise => get-at obj[first path], (tail path), sep
