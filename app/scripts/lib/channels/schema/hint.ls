module.exports = {
  name: \hint
  schema:
    type: {type: \string, +required}
    name: {type: \string, +required}

  parse: (str) ->
    hint-events = str
      |> split ','
      |> map ( .trim! )
      |> map (hint-event) ->
        hint-event |> split ':' |> ( -> {name: it.0, type: it.1} )

    (hint-event) ->
      for he-spec in hint-events
        if he-spec.name is hint-event.name and he-spec.type is hint-event.type
          return true

      return false
}
