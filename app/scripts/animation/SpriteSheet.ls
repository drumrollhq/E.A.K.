require! {
  'lib/channels'
  'translations'
}

module.exports = class SpriteSheet extends Backbone.View
  @create = (el) ->
    ss = new SpriteSheet {el}
    ss.load!.then -> ss

  initialize: ({cb}) ->
    @$el.data 'sprite-controller', this

    @url = @$el.attr 'data-sprite'
    speed = @$el.attr 'data-sprite-speed'
    size = @$el.attr 'data-sprite-size'
    frames = @$el.attr 'data-sprite-frames'
    start-frame = @$el.attr 'data-sprite-start-frame' or '0'
    @state = @$el.attr 'data-sprite-state' or 'play'
    loop-times = @$el.attr 'data-sprite-loop' or '0'
    delay-range = @$el.attr 'data-sprite-delay' or '0'

    @speed = 1000 * parse-float speed
    @frames = parse-int frames
    @start-frame = parse-int start-frame
    @loop-times = parse-int loop-times

    if delay-range.match /-/
      [mn, mx] = delay-range |> split '-' |> map parse-float
    else mx = mn = parse-float delay-range
    if mx is mn
      if mx is 0
        @delay = false
      else
        @delay = (cb) ->
          set-timeout cb, mx * 1000
    else
      @delay = (cb) ->
        t = mn + Math.random! * (mx - mn)
        set-timeout cb, t * 1000

    @duration = @speed * @frames

    [width, height] = size |> split 'x' |> map ( .trim! ) |> map parse-int
    @size = {width, height}
    @$el.add-class 'sprite-anim'
    @$el.css @size.{width, height}


  load: ->
    @load-image! .then ~>
      @setup-renderer!
      @frame-sub = channels.frame.subscribe @frame
      @_start-time = performance.now!
      @render-frame @start-frame

      if @state.to-lower-case! is 'paused' then @stop!

  stop: ~>
    @frame-sub.pause!

  play: ~>
    @frame-sub.resume!

  restart: ~>
    @_start-time = performance.now!
    @frame-sub.resume!

  setup-renderer: ~>
    @canvas = document.create-element \canvas
    @$canvas = $ @canvas
    @$canvas.attr {
      width: @size.width * @scale-factor
      height: @size.height * @scale-factor
    }

    @$canvas.css @size.{width, height}

    @ctx = @canvas.get-context '2d'
    @$el.append @canvas

  load-image: ~> new Promise (resolve, reject) ~>
    @img = img = new Image!
    $img = $ img
    $img.on 'load' (e) ~>
      @scale-factor = img.height / @size.height
      resolve img

    $img.on 'error' (e) ~>
      channels.alert.publish {msg: "#{translations.errors.load-sprite} #{@url}"}
      reject e

    img.src = "#{@url}?_v=#{EAKVERSION}"

  frame: ~>
    elapsed = performance.now! - @_start-time

    if @loop-times isnt 0 and elapsed > @loop-times * @duration then return
    if elapsed > @duration and @delay
      @stop!
      @delay @restart
      return

    frame = (@start-frame + elapsed / @speed) % @frames .|. 0
    if frame isnt @_last-frame then @render-frame frame

  render-frame: (n) ~>
    @_last-frame = n
    cw = @canvas.width
    ch = @canvas.height
    @ctx.clear-rect 0, 0, cw, ch
    @ctx.draw-image @img, n * cw, 0, cw, ch, 0, 0, cw, ch

  remove: ~>
    super!
    @frame-sub.unsubscribe! if @frame-sub._subscribed
