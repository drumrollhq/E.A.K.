module.exports = class GeneralBody extends Backbone.Model
  (def) ->
    @def = def

    s = @def

    @data = s.{}data

    ids = <[ * ]>

    if s.id? then ids.push s.id

    if s.el?
      {el} = s
      ids.push '#' + el.id if el.id isnt ""
      for class-name in el.class-list => ids.push '.' + class-name

      if s.el.tag-name.to-lower-case! is \a then ids.push \HYPERLINK

    if @data.id? then ids.push @data.id

    @ <<< {ids}

  get-sanitised-def: ->
    out = _.clone @def
    out <<< el: undefined, ids: @ids
    out

  attach-to: (world) ~>
    @uid = world.attach-body @
    @world = world
    @worker = world.worker

  call: (name, args, done) ~>
    if done is undefined and typeof args is \function
      done = args
      args = <[ kittens ]>

    @worker.send \entityCall {@uid, name, args} done

  destroy: (callback) ~> @call \destroy, callback
  halt: (callback) ~> @call \halt, callback
  reset: (callback) ~> @call \reset, callback
  is-awake: (callback) ~> @call \isAwake, callback
  position: (p, callback) ~> @call \position, [p], callback
  position-uncorrected: (callback) ~> @call \positionUncorrected, callback
  absolute-position: (callback) ~> @call \absolutePosition, callback
  angle: (callback) ~> @call \angle, callback
  angular-velocity: (callback) ~> @call \angularVelocity, callback
  linear-velocity: (callback) ~> @call \lineatVelocity, callback
  apply-torque: (n, callback) ~> @call \applyTorque, [n], callback
