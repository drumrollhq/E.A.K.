to-boolean = (str) ->
  str = str.trim!.to-lower-case!
  match str
  | '' => false
  | 'true' or 't' => true
  | 'false' or 'f' => false
  | otherwise => false

to-list = (str = '', delimeter = ' ') ->
  str.trim!
  |> split delimeter
  |> reject empty

to-coordinates = (str = '0 0', delimeter = ' ') ->
  parts = to-list str, delimeter
  if parts.length isnt 2 then throw new Error 'Cannot parse coordinates. Wrong number of parts'
  parts.map parse-float

tidy-key = (key = '') ->
  key .= replace /:$/ ''
  camelize key

to-object = (str) ->
  pairs = str
    |> to-list _, ','
    |> map to-list
    |> reject head >> empty

  keys = pairs
    |> map head >> tidy-key

  values = pairs
    |> map tail >> unwords >> ( .trim! )

  lists-to-obj keys, values

# Naive query-string parsing
query-string = (q) ->
  pairs = q.replace /^\?/ ''
  |> split '&'
  |> map split '='

  {[(tidy-key pair.0), pair.1] for pair in pairs}

a-tag = document.create-element \a
url = (str) ->
  a-tag.href = str
  url = a-tag.{protocol, hostname, port, pathname, search, hash, host}
  url.query = query-string url.search
  url.pathname .= replace /^\/\// ''
  url

module.exports = {to-boolean, to-bool: to-boolean, to-list, to-coordinates, to-object, tidy-key, url, query-string}
