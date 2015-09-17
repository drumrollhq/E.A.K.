module.exports = {
  name: \triggers
  schema:
    id: {type: \string, +required}
    payload: {type: \object, +optional}

  parse: (str) ->
    ids = str |> split ',' |> map ( .trim! )
    (e) -> e.id in ids
}
