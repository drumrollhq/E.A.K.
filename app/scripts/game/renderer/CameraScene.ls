require! {
  'channels'
}

transform = prefixed.transform
counter = 0

const pad = 30
const damping = 10

range = (min1, max1, min2, max2, x) -->
  n = (x - min1) / (max1 - min1)
  min2 + (n * (max2 - min2))

constrain = (min, max, x) -->
  | x < min => min
  | x > max => max
  | otherwise => x

module.exports = class CameraScene extends Backbone.View
  tag-name: \div
  class-name: 'camera-scene'
  id: -> "camerascene-#{counter++}-#{Date.now!}"

  initialize: ({track-channel}) ->
    this <<< {track-channel}
    @subs = []
    @subs[*] = channels.window-size.subscribe @resize
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

    console.log {actual-width, actual-height, el-width, el-height, win-width, win-height}

    scrolling = x: no, y: no
    @last-position = x: 0, y: 0 unless @last-position?

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
    lx = @last-position.x
    ly = @last-position.y


    t = {
      x: lx + (x - lx) / damping
      y: ly + (y - ly) / damping
    }

    @last-position = t
    @move-direct t

  move-direct: (position, scroll = false) ~>
    s = @scrolling
    w = @el-width - (s.x - margin * 2)
    h = @el-height - (s.y - margin * 2)

    x = position.x |> range margin, @width - margin, 0, w |> constrain 0, w
    y = position.y |> range margin, @height - margin, 0, h |> constrain 0, h

    t = {
      x: if s.x then x else 0
      y: if s.y then y else 0
    }

    @el.style[transform] = if t.x is 0 and t.y is 0 then '' else
      "translate3d(#{-t.x}px, #{-t.y}px, 0)"

  clear-position: ~>
    @el.style[transform] = 'translate3d(0, 0, 0)'
    @last-position = x: 0, y: 0

  $window: $ window

