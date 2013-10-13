require! {
  "mediator"
  "physics/WorldListener"
  "physics/StaticBody"
  "physics/DynamicBody"
  "physics/PlayerBody"
}

Vector = Box2D.Common.Math.b2Vec2
b2World = Box2D.Dynamics.b2World

working = no

class World
  ->
    g = new Vector 0, 10
    @world = new b2World g, true
    @entities = []

    new WorldListener! |> @world.SetContactListener

    mediator.on do
      "triggerUpdate": @update
      "create:body": @create-body
      "entityCall": @entity-call

  update: (t, done) ~>
    unless working
      working = yes
      @world.Step t/1000, 10, 10
      @world.ClearForces!
      updates = []
      mediator.trigger "collectUpdates", updates
      done updates
      working = no

  create-body: (data) ~>
    {uid, def} = data

    body = switch def.body-type
      when \static then new StaticBody def, uid, World::scale
      when \dynamic then new DynamicBody def, uid, World::scale
      when \player then new PlayerBody def, uid, World::scale
      else throw new Error "Unknown body-type: #{def.body-type}"

    console.log "Created #{def.body-type} body:", body.ids, def

    body.attach-to @
    @entities[uid] = body

  entity-call: (data, done) ~>
    entity = @entities[data.uid]
    entity[data.name].apply entity, data.args |> done

  scale: 40

new World!
