module.exports = class GeneralBody extends Backbone.Model
  constructor: (def) ->
    @def = def

    s = @def

    @data = s.data

    ids = ["*"]
    if s.id isnt undefined
      ids.push s.id

    if s.el isnt undefined
      el = s.el
      ids.push "#" + el.id if el.id isnt ""
      ids.push "." + className for className in el.classList

    ids.push @data.id if @data.id isnt undefined

    @ids = ids

  getSanitisedDef: ->
    out = _.clone @def
    out.el = undefined
    out.ids = @ids
    out

  attachTo: (world) =>
    @uid = world.attachBody @getSanitisedDef()

  destroy: =>
    if @world isnt undefined then @world.world.DestroyBody @body

  halt: =>
    b = @body
    b.SetAngularVelocity 0
    b.SetLinearVelocity new Vector 0, 0

  reset: =>
    @halt()
    @position x:0, y: 0
    @body.SetAngle 0

  isAwake: -> @body.GetType() isnt 0 and @body.IsAwake()

  position: (p) ->
    if p is undefined
      p = @body.GetPosition()
      return x: (p.x * scale) - @def.x, y: (p.y * scale) - @def.y
    else
      @body.SetPosition new Vector (p.x + @def.x) / scale, (p.y + @def.y) / scale

  positionUncorrected: ->
    p = @body.GetPosition()
    x: (p.x * scale), y: (p.y * scale)

  absolutePosition: ->
    p = @body.GetPosition()
    x: p.x * scale, y: p.y * scale

  angle: -> @body.GetAngle()

  angularVelocity: -> @body.GetAngularVelocity()

  defDefaults:
    x: 0
    y: 0
    width: 1
    height: 1
    radius: 0
    type: "rect"
