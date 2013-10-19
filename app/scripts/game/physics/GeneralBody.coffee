module.exports = class GeneralBody extends Backbone.Model
  constructor: (def) ->
    @def = def

    s = @def

    @data = s.data or {}

    ids = ["*"]
    if s.id isnt undefined
      ids.push s.id

    if s.el isnt undefined
      el = s.el
      ids.push "#" + el.id if el.id isnt ""
      ids.push "." + className for className in el.classList

      if s.el.tagName.toLowerCase() is 'a' then ids.push 'HYPERLINK'

    ids.push @data.id if @data.id isnt undefined

    @ids = ids

  getWorkerFn: (name) => return => @call "name", (_.initial arguments), _.last arguments

  getSanitisedDef: ->
    out = _.clone @def
    out.el = undefined
    out.ids = @ids
    out

  attachTo: (world) =>
    @uid = world.attachBody @
    @world = world
    @worker = world.worker

  call: (name, args, done) =>
    if done is undefined and typeof args is "function"
      done = args
      args = ["kittens"]

    @worker.send "entityCall",
      uid: @uid
      name: name
      args: args
    , done

  destroy: (callback) => @call "destroy", callback
  halt: (callback) => @call "halt", callback
  reset: (callback) => @call "reset", callback
  isAwake: (callback) => @call "isAwake", callback
  position: (p, callback) => @call "position", [p], callback
  positionUncorrected: (callback) => @call "positionUncorrected", callback
  absolutePosition: (callback) => @call "absolutePosition", callback
  angle: (callback) => @call "angle", callback
  angularVelocity: (callback) => @call "angularVelocity", callback
  applyTorque: (n, callback) => @call "applyTorque", [n], callback
