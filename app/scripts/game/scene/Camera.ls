range = (min1, max1, min2, max2, x) -->
  n = (x - min1) / (max1 - min1)
  min2 + (n * (max2 - min2))

constrain = (min, max, x) -->
  | x < min => min
  | x > max => max
  | otherwise => x

lerp = (a, b, x) --> a + x * (b - a)

module.exports = class Camera
  (size, @speed, @padding) ->
    @scene-width = size.width
    @scene-height = size.height
    @_adjusted-scene-width = @scene-width - @padding
    @_adjusted-scene-height = @scene-height - @padding

  track: (display-object) ->
    @_tracking = display-object

  pause-tracking: ->
    @_last-tracked = @_tracking
    @_tracking = null

  resume-tracking: ->
    @_tracking = @_last-tracked

  set-viewport: (width, height) ->
    @_viewport-width = width
    @_viewport-height = height
    if width < @_adjusted-scene-width
      @_lock-x = null
    else
      @_lock-x = (@scene-width - width) / 2

    if height < @_adjusted-scene-height
      @_lock-y = null
    else
      @_lock-y = (@scene-height - height) / 2

  set-subject: ({x, y}) ->
    @_subject-x = x
    @_subject-y = y

  step: ->
    if @_tracking then @set-subject @_tracking.p

    [@target-x, @target-y] =
      if @_editing then @get-editing-position! else @get-target-position!

    p = @tween-position @target-x, @target-y, @speed
    @offset-x = p.x
    @offset-y = p.y

  get-target-position: ->
    max-x = @scene-width - @_viewport-width
    max-y = @scene-height - @_viewport-height
    target-x = if @_lock-x? then @_lock-x
      else constrain 0, max-x, @_subject-x - @_viewport-width / 2
    target-y = if @_lock-y? then @_lock-y
      else constrain 0, max-y, @_subject-y - @_viewport-height / 2

    [target-x, target-y]

  start-edit-mode: (rect, duration, frame-driver) -> new Promise (resolve, reject) ~>
    @_editing = true
    @_edit-rect = rect
    @_normal-speed = @speed
    @speed = 100/duration

    sub = frame-driver.subscribe ~>
      @step!
      dx = @target-x - @offset-x
      dy = @target-y - @offset-y
      dist = dx * dx + dy * dy
      if dist < 10
        sub.unsubscribe!
        @speed = 1
        resolve!

  get-editing-position: ->
    const pad = 30px
    {top, left, height, width} = @_edit-rect
    target-x = if @_viewport-width/2 < pad + pad + width
      left - @_viewport-width/2 - pad
    else left - @_viewport-width*0.75 + width/2
    target-y = top - @_viewport-height/2 + height/2
    [target-x, target-y]

  tween-position: (x, y, speed) ->
    px = @_px or 0.1
    py = @_py or 0.1
    qx = @_qx or 0.1
    qy = @_qy or 0.1

    px1 = lerp px, x, speed
    py1 = lerp py, y, speed
    qx1 = lerp qx, px1, speed
    qy1 = lerp qy, py1, speed

    @_px = px1
    @_py = py1
    @_qx = qx1
    @_qy = qy1
    {x: qx1, y: qy1}
