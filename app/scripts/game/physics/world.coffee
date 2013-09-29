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

    @worker.on "contactEvent", @contactEvent

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

  contactEvent: (evt) =>
    type = evt.type
    a = @bodies[evt.a]
    b = @bodies[evt.b]

    for idA in a.ids
      for idB in b.ids
        mediator.trigger "#{type}Contact:#{idA}&#{idB}",
          a: a
          b: b
        mediator.trigger "#{type}Contact:#{idB}&#{idA}",
          a: a
          b: b
