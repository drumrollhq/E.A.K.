WebWorker = require "webworker"
mediator = require "game/mediator"

uidCounter = 1

newUID = -> uidCounter++

module.exports = class World extends Backbone.Model
  initialize: ->
    @worker = new WebWorker name: "physics/world"

    @bodies = []

    mediator.on "frame:process", (t) =>
      @worker.send "triggerUpdate", t, @update

  attachBody: (body) =>
    id = newUID()
    @worker.send "create:body",
      uid: id
      def: body.getSanitisedDef()

    @bodies[id] = body

    id

  update: (updates) =>
    for update in updates
      body = @bodies[update.uid]
      body.render update.position, update.angle
