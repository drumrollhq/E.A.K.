require! {
  'lib/parse'
}

split-texture = (texture, frames) ->
  width = texture.width / frames

  for i til frames
    rect = new PIXI.Rectangle width * i, 0, width, texture.height
    new PIXI.Texture texture, rect

module.exports = class SpriteSheet extends PIXI.MovieClip
  @from-el = (el, offset-x, offset-y) ->
    $el = $ el
    url = $el.attr \data-sprite
    frames = $el.attr \data-sprite-frames
    size = $el.attr \data-sprite-size
    pos = $el.attr \data-sprite-pos or '0 0'
    speed = $el.attr \data-sprite-speed
    start-frame = $el.attr \data-sprite-start-frame or \0
    state = $el.attr \data-sprite-state or \play
    loop-times = $el.attr \data-sprite-loop or \0
    delay-range = $el.attr \data-sprite-delay or \0

    speed = (parse-float speed)
    frames = parse-int frames
    start-frame = parse-int start-frame
    loop-times = parse-int loop-times
    [x, y] = parse.to-coordinates pos
    x += offset-x
    y += offset-y

    if delay-range.match /-/
      delay = [min, max] = delay-range |> split '-' |> map parse-float
    else min = max = parse-float delay-range
    if max is min
      delay = max

    [width, height] = size
      |> split 'x'
      |> map ( .trim! )
      |> map parse-float

    sprite-sheet = new SpriteSheet url, frames, width, height, x, y, {speed, start-frame, state, loop-times, delay}
    $el.data \sprite-controller sprite-sheet
    sprite-sheet

  defaults:
    speed: 60
    start-frame: 0
    state: \play
    loop-times: 0
    delay: 0

  (src, frames, @_initial-width, @_initial-height, @_x, @_y, options = {}) ->
    _.mixin this, Backbone.Events
    @options = _.defaults options, SpriteSheet::defaults
    @_texture-promise = PIXI.load-texture src
      .then (texture) ~> @_setup texture, frames

    @on \add, (layer) ~> console.log \ADD layer

  load: ->
    @_texture-promise

  _setup: (texture, frames) ->
    textures = split-texture texture, frames
    PIXI.MovieClip.call this, textures
    delete @on-complete # pixi sets on-complete to null
    @children = []
    @width = @_initial-width
    @height = @_initial-height
    @x = @_x
    @y = @_y
    @loop = false
    @animation-speed = @options.speed / 60
    @_loop-count = 0
    if @options.state is \play
      @goto-and-play @options.start-frame
    else @goto-and-stop @options.start-frame

  on-complete: ->
    @_loop-count++
    unless @options.loop-times > 0 and @_loop-count >= @options.loop-times
      @delay!.then ~> @goto-and-play @options.start-frame

  delay: ->
    delay = @options.delay or 0
    if typeof delay is \number then return Promise.delay delay * 1000
    [min, max] = delay
    return Promise.delay (min + Math.random! * (max - min)) * 1000
