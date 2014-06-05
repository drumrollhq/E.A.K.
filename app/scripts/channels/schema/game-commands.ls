module.exports = {
  name: \game-commands
  schema:
    command: {type: \string, +required}
    payload: {type: \object, +optional}

  parse: (str) ->
    commands = str |> split ',' |> map ( .trim! )
    (e) -> e.command in commands
}
