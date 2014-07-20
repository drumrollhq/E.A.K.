module.exports = {
  name: \track-volume
  schema:
    track: {type: \string, +required}
    value: {type: \number, +required}

  parse: (str) ->
    tracks = str |> split ',' |> map ( .trim! )
    (e) -> e.track in tracks
}
