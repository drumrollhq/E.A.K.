module.exports = {
  name: \page
  schema:
    name: {type: \string, +required}
    prev: {type: \string, +optional}

  parse: (str) ->
    commands = str |> split ',' |> map ( .trim! )
    (e) -> e.command in commands
}
