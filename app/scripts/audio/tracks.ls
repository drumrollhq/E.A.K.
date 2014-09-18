class Tracks
  ->
    @_tracks = {}

  add: (name, track) ->
    @_tracks[name] = track

  get: (name) -> @_tracks[name]

  focus: (name) ->
    for track-name, track of @_tracks
      if track-name is name then track.fade 1 else track.fade 0.1

  blur: ->
    for track-name, track of @_tracks => track.fade 1

module.exports = new Tracks!
