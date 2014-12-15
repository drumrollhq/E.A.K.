require! {
  'channels'
}

transform = prefixed.transform
counter = 0

const pad = 30
const speed = 0.2

range = (min1, max1, min2, max2, x) -->
  n = (x - min1) / (max1 - min1)
  min2 + (n * (max2 - min2))

constrain = (min, max, x) -->
  | x < min => min
  | x > max => max
  | otherwise => x

lerp = (a, b, x) --> a + x * (b - a)

module.exports = class CameraScene extends Backbone.View
  tag-name: \div
  class-name: 'camera-scene'
  id: -> "camerascene-#{counter++}-#{Date.now!}"

  initialize: ({track-channel}) ->
    this <<< {track-channel}
    @subs = []
    @subs[*] = channels.window-size.subscribe ~> @resize!
    @subs[*] = track-channel.subscribe @move
    @resize!

  remove: ~>
    for sub in @subs => @sub.unsubscribe!
    @subs = null

  const margin = 250

  resize: ~>
    actual-width = @width = @$el.width!
    actual-height = @height = @$el.height!
    el-width = @el-width = actual-width - margin*2
    el-height = @el-height = actual-height - margin*2
    win-width = @$window.width!
    win-height = @$window.height!

    scrolling = x: no, y: no

    if win-width < el-width
      scrolling.x = win-width
      @$el.css left: 0, margin-left: 0
    else
      @$el.css left: '50%', margin-left: - actual-width / 2

    if win-height < el-height
      scrolling.y = win-height
      @$el.css top: 0, margin-top: 0
    else
      @$el.css top: '50%', margin-top: - actual-height / 2

    @scrolling = scrolling

  set-width: (width) ~>
    @$el.width width
    @resize!

  set-height: (height) ~>
    @$el.height height
    @resize!

  set-size: (width, height) ~>
    @$el.width width
    @$el.height height
    @resize!

  move: ({x, y}) ~>
    p = @get-position x, y
    q = @tween-position p.x, p.y
    @set-transform if @scrolling.x then -q.x else 0, if @scrolling.y then -q.y else 0

  get-position: (x, y) ->
    s = @scrolling
    w = @el-width - (s.x - margin * 2)
    h = @el-height - (s.y - margin * 2)

    x = x |> range margin, @width - margin, 0, w |> constrain 0, w
    y = y |> range margin, @height - margin, 0, h |> constrain 0, h

    {x, y}

  tween-position: (x, y) ->
    if @p?
      px = @p.x
      py = @p.y
    else
      @p = {}
      px = x
      py = y

    if @q?
      qx = @q.x
      qy = @q.y
    else
      @q = {}
      qx = px
      qy = py

    px1 = lerp px, x, speed
    py1 = lerp py, y, speed
    qx1 = lerp qx, px1, speed
    qy1 = lerp qy, py1, speed

    @p <<< {x: px1, y: py1}
    @q <<< {x: qx1, y: qy1}
    @q

  set-transform: (x, y) ->
    @el.style[transform] = if x is 0 and y is 0 then '' else
      "translate3d(#{x}px, #{y}px, 0)"

  clear-position: ~>
    @el.style[transform] = 'translate3d(0, 0, 0)'
    @p = @q = null

  $window: $ window

