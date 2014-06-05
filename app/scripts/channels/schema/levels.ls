module.exports = {
  name: \levels
  schema:
    url: {type: \string, +required}

  parse: (str) ->
    urls = str |> split ',' |> map ( .trim! )
    (level) -> level.url in urls
}
