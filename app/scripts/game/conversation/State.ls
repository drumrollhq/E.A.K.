id-counter = 0

module.exports = class State extends Backbone.DeepModel
  add-line: (speaker, line, from-player = false, track = null, options = []) ->
    lines = @get \lines
    audio-root = @get \audioRoot or '/audio/conversations'
    lines.push {speaker, line, id: id-counter++, from-player, audio-root, track, options}
    @trigger \change
    Promise.all [
      wait-for-event this, \line-first-play-completed
      Promise.delay 500
    ] .then -> Promise.delay 250
