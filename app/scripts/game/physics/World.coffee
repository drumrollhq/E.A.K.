WebWorker = require "WebWorker"
mediator = require "game/mediator"

uidCounter = 1

newUID = -> uidCounter++

module.exports = class World extends Backbone.Model
  initialize: ->
    @worker = new WebWorker name: "physics/World"

    @bodies = []

    @updates = []

    @listenTo mediator, "frame:process", (t) =>
      @worker.send "triggerUpdate", t, (updates) => @updates = updates

    @listenTo mediator, "frame:render", @update

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

  remove: =>
    delete @bodies
    @worker.kill()
    @stopListening()

  contactEvent: (evt) =>
    type = evt.type
    a = @bodies[evt.a]
    b = @bodies[evt.b]

    for idA in a.ids
      for idB in b.ids
        mediator.trigger "#{type}Contact:#{idA}&#{idB}",
          a: a
          b: b
          pre: evt.pre
          post: evt.post
          impulse: evt.impulse or {}
        mediator.trigger "#{type}Contact:#{idB}&#{idA}",
          a: a
          b: b
          pre: evt.pre
          post: evt.post
          impulse: evt.impulse or {}
