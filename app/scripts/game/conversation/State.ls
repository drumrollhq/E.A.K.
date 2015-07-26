id-counter = 0

module.exports = class State extends Backbone.DeepModel
  add-line: (speaker, line) ->
    lines = @get \lines
    lines.push {speaker, line, id: id-counter++}
    @trigger \change
