id-counter = 0

module.exports = class State extends Backbone.DeepModel
  add-line: (speaker, line, from-player = false) ->
    lines = @get \lines
    lines.push {speaker, line, id: id-counter++, from-player}
    @trigger \change
