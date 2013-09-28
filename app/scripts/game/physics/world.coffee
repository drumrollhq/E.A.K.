WebWorker = require "webworker"
mediator = require "game/mediator"

uidCounter = 1

newUID = -> uidCounter++

module.exports = class World extends Backbone.Model
  initialize: ->
    @worker = new WebWorker name: "physics/world"

    mediator.on "frame:process", (t) =>
      id = newUID()
      @worker.send "triggerUpdate", id

  attachBody: (def) =>
    id = newUID()
    @worker.send "create:body",
      uid: id
      def: def
