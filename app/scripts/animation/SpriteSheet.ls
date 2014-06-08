require! 'channels'

module.exports = class SpriteSheet extends Backbone.View
  initialize: ({cb}) ->
    @url = @$el.attr 'data-sprite'
    speed = @$el.attr 'data-sprite-speed'
    size = @$el.attr 'data-sprite-size'
    frames = @$el.attr 'data-sprite-frames'

    @speed = 1000 * parse-float speed
    @frames = parse-int frames

    [width, height] = size |> split 'x' |> map ( .trim! ) |> map parse-int
    @size = {width, height}
    @$el.add-class 'sprite-anim'
    @$el.css @size.{width, height}

    err <~ @load-image!
    cb err
    if err? then return

    @setup-renderer!
    @frame-sub = channels.frame.subscribe @frame
    @_start-time = performance.now!
    @render-frame 0

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

  load-image: (done) ~>
    @img = img = new Image!
    $img = $ img
    $img.on 'load' (e) ~>
      @scale-factor = img.height / @size.height
      console.log @{scale-factor}
      done!

    $img.on 'error' (e) ~>
      channels.alert.publish {msg: "Error: Cannot load sprite #{@url}"}
      done e

    img.src = @url

  frame: ~>
    elapsed = performance.now! - @_start-time
    frame = (elapsed / @speed) % @frames .|. 0
    if frame isnt @_last-frame then @render-frame frame

  render-frame: (n) ~>
    @_last-frame = n
    cw = @canvas.width
    ch = @canvas.height
    @ctx.clear-rect 0, 0, cw, ch
    @ctx.draw-image @img, n * cw, 0, cw, ch, 0, 0, cw, ch
