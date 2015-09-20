require! 'assets'

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
    @options = options = {} <<< options
    @_emit-timer = 0
    @_pool = []

    @_paused = false

    @_urls = flatten [options.url] |> map -> assets.load-asset it, \url
    @_load = Promise.map @_urls, PIXI.load-texture
    @sprite-url = random-picker @_urls

    rate-range = random-range options.rate
    @emit-rate = -> 1000ms / rate-range!
    @_next-emit-time = @emit-rate!
    @particle-lifetime = random-range options.lifetime

    if typeof! options.scale in <[Number Array]>
      @initial-scale = random-range options.scale
      delete options.scale

    if options.v-x? then @initial-v-x = random-range options.v-x
    if options.v-y? then @initial-v-y = random-range options.v-y
    if options.v-r? then @initial-v-r = random-range options.v-r
    if options.a-x? then @initial-a-x = random-range options.a-x
    if options.a-y? then @initial-a-y = random-range options.a-y
    if options.blend-mode? then @blend-mode = options.blend-mode

  pause: ->
    @_paused = true

  resume: ->
    @_paused = false

  step: (dt) ->
    @_emit-timer += dt * 16.6
    if @_emit-timer > @_next-emit-time
      @_emit-timer = @_emit-timer % @_next-emit-time
      @_next-emit-time = @emit-rate!
      @emit!

    {x, y, scale, alpha} = @options
    i = 0
    len = @children.length
    while i < len
      particle = this.children[i]
      i++

      {age, lifetime, v-r, v-x, v-y, a-x, a-y} = particle
      if age > lifetime
        @kill particle
        len--
        i--
        continue

      if x then particle.position.x = particle.start-x + x age, lifetime, particle
      if y then particle.position.y = particle.start-y + y age, lifetime, particle
      if scale then particle.scale.x = particle.scale.y = scale age, lifetime, particle
      if alpha then particle.alpha = alpha age, lifetime, particle
      if v-x then particle.position.x += v-x * dt
      if v-y then particle.position.y += v-y * dt
      if v-r then particle.rotation += v-r * dt
      if a-x then particle.v-x += a-x * dt
      if a-y then particle.v-y += a-y * dt
      particle.age += dt * 16.6

  emit: ->
    if @_paused then return
    particle = if @_pool.length
      @_pool.shift!
    else
      new PIXI.Sprite.from-image @sprite-url!

    particle.blend-mode = this.blend-mode if this.blend-mode?
    particle.age = 0
    particle.lifetime = @particle-lifetime!
    particle.x = particle.start-x = @emitter.x
    particle.y = particle.start-y = @emitter.y
    particle.anchor.x = 0.5
    particle.anchor.y = 0.5
    particle.v-x = @initial-v-x! if @initial-v-x
    particle.v-y = @initial-v-y! if @initial-v-y
    particle.v-r = @initial-v-r! if @initial-v-r
    particle.a-x = @initial-a-x! if @initial-a-x
    particle.a-y = @initial-a-y! if @initial-a-y
    particle.scale.x = particle.scale.y = @initial-scale! if @initial-scale
    @add-child particle

  kill: (particle) ->
    @remove-child particle
    @_pool[*] = particle

  load: -> @_load

