id-counter = 0

module.exports = class State extends Backbone.DeepModel
  add-line: (speaker, line, from-player = false, track = null, options = []) ->
    lines = @get \lines
    audio-root = @get \audioRoot or '/audio/conversations'
    lines.push {speaker, line, id: id-counter++, from-player, audio-root, track, options}
    @trigger \change
    min-length = if \run-on in options then 0 else 500
    delay = if \run-on in options then 0 else 250
    Promise.all [
      wait-for-event this, \line-first-play-completed
      Promise.delay min-length
    ] .then -> Promise.delay delay
