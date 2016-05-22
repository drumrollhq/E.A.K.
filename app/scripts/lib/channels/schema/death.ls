module.exports = {
  name: \death
  schema:
    cause: {type: \string, +required}
    data: {type: \object, +optional}

  parse: (str) ->
    causes = str |> split ',' |> map ( .trim! )
    (death) -> death.cause in causes
}
