require! {
  'audio/play-conversation-line'
}

id-counter = 0

module.exports = class State extends Backbone.DeepModel
  add-line: (speaker, line, from-player = false, track = null) ->
    lines = @get \lines
    lines.push {speaker, line, id: id-counter++, from-player}
    @trigger \change
    if track
      play-conversation-line (@get \audioRoot or '/audio/conversations'), track
    else
      Promise.delay 1000
