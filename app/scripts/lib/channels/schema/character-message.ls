module.exports = do
  name: \character-message
  schema:
    from: {type: \string, +required}
    content: {type: \string, +required}
    track: {type: \string, +optional}
    timeout: {type: \number, +optional}

  parse: (str) ->
    froms = str |> split ',' |> map ( .trim! )
    (e) -> e.from in froms
