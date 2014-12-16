require! 'channels'

const DEBUG = true

temps = []
channels.frame.subscribe -> while t = temps.shift! => t.free!

module.exports = class Pool
  (@name, @_ctor, @_reset, n = 1) ->
    @_available = []
    @_created = 0
    for i til n => @create!

  create: ->
    t = @_ctor!
    @_available[*] = t
    @_created++

    Object.define-property t, 'free', {
      configurable: false
      enumerable: false
      writable: false
      value: ~>
        @_reset t
        @_available[*] = t
        if DEBUG then console.log "[pool] free #{@name}. #{@_status!}"
    }

    if DEBUG then console.log "[pool] create new #{@name}. #{@_status!}"
    t

  alloc: ->
    if @_available.length > 0
      res = @_available.shift!
      if DEBUG then console.log "[pool] allocate #{@name}. #{@_status!}"
      res
    else @create-and-alloc!

  # tmp: A temporarily allocated object. This object is automatically
  # `free`d on the next `frame` event. Use with caution.
  tmp: ->
    t = @alloc!
    temps.push t
    t

  create-and-alloc: ->
    @create!
    @alloc!

  _status: -> "#{@_available.length}/#{@_created} available."
