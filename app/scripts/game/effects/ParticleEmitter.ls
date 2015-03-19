random-picker = (arr) ->
  -> arr[Math.floor Math.random! * arr.length]

rand-between = (min, max) ->
  -> min + Math.random! * (max - min)

random-range = (range) ->
  | typeof! range is \Number => -> range
  | typeof! range is \Array => rand-between range[0], range[1]
  | typeof! range is \Function => range

module.exports = class ParticleEmitter extends PIXI.Container
  (@emitter, options) ->
    super!
    @options = options
    @_emit-timer = 0
    @_pool = []
    rate-range = random-range options.rate
    @emit-rate = -> 1000ms / rate-range!
    @_next-emit-time = @emit-rate!

    @_urls = flatten [options.url]
    @_load = Promise.map @_urls, PIXI.load-texture
    @sprite-url = random-picker @_urls
    @particle-lifetime = random-range options.lifetime
    if options.scale
      options.scale-x = options.scale
      options.scale-y = options.scale

  step: (dt) ->
    @_emit-timer += dt
    if @_emit-timer > @_next-emit-time
      @_emit-timer = @_emit-timer % @_next-emit-time
      @_next-emit-time = @emit-rate!
      @emit!

    {x, y, scale-x, scale-y, alpha} = @options
    i = 0
    len = @children.length
    while i < len
      particle = this.children[i]
      i++

      {age, lifetime} = particle
      if age > lifetime
        @kill particle
        len--
        i--
        continue
      if x then particle.position.x = particle.start-x + x age, lifetime, particle
      if y then particle.position.y = particle.start-y + y age, lifetime, particle
      if scale-x then particle.scale.x = scale-x age, lifetime, particle
      if scale-y then particle.scale.y = scale-y age, lifetime, particle
      if alpha then particle.alpha = alpha age, lifetime, particle
      particle.age += dt

  emit: ->
    particle = if @_pool.length
      @_pool.shift!
    else
      new PIXI.Sprite.from-image @sprite-url!

    particle.age = 0
    particle.lifetime = @particle-lifetime!
    particle.x = particle.start-x = @emitter.x
    particle.y = particle.start-y = @emitter.y
    particle.anchor.x = 0.5
    particle.anchor.y = 0.5
    @add-child particle

  kill: (particle) ->
    @remove-child particle
    @_pool[*] = particle

  load: -> @_load

