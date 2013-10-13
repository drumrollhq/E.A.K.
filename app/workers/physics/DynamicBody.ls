require! {
  "mediator"
  "physics/GeneralBody"
}

b2Body = Box2D.Dynamics.b2Body

module.exports = class DynamicBody extends GeneralBody
  (def, uid, scale) ->
    super def, uid, scale
    @bd.type = b2Body.b2_dynamicBody
    @initialize!

    mediator.on \collectUpdates @render
    console.log "Created dynamic body #uid"

  render: (updates) ~>
    {body} = @

    if @is-awake!
      updates.push do
        uid: @uid
        position: @position!
        angle: @angle!

