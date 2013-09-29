WebWorker = require "webworker"
mediator = require "game/mediator"

uidCounter = 1

newUID = -> uidCounter++

module.exports = class World extends Backbone.Model
  initialize: ->
    @worker = new WebWorker name: "physics/world"

    @bodies = []

    @updates = []

    mediator.on "frame:process", (t) =>
      @worker.send "triggerUpdate", t, (updates) => @updates = updates

    mediator.on "frame:render", @update

  attachBody: (body) =>
    id = newUID()
    @worker.send "create:body",
      uid: id
      def: body.getSanitisedDef()

    @bodies[id] = body

    id

  update: =>
    for update in @updates
      body = @bodies[update.uid]
      body.render update.position, update.angle

    @updates = []
