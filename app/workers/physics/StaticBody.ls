require! "physics/GeneralBody"

b2Body = Box2D.Dynamics.b2Body

module.exports = class StaticBody extends GeneralBody
  (def, uid, scale) ->
    super def, uid, scale
    @bd.type = b2Body.b2_staticBody
    @initialize!
    console.log "Created static body #{@uid}"
