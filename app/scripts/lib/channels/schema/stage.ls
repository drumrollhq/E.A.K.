module.exports = {
  name: \stage
  schema:
    url: {type: \string, +required}
    type: {type: \string, +required}

  parse: (str) ->
    urls = str |> split ',' |> map ( .trim! )
    (level) -> level.url in urls
}
