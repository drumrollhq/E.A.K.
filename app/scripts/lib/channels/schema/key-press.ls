module.exports = {
  name: \key-press
  schema:
    code: {type: \number, +required}
    key: {type: \string, +required}

  parse: (str) ->
    allowed-keys = str |> split "," |> map ( .trim! )
    return (e) -> e.key in allowed-keys
}
