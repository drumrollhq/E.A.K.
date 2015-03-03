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

    max-x = @scene-width - @_viewport-width
    max-y = @scene-height - @_viewport-height
    target-x = if @_lock-x? then @_lock-x
      else constrain 0, max-x, @_subject-x - @_viewport-width / 2
    target-y = if @_lock-y? then @_lock-y
      else constrain 0, max-y, @_subject-y - @_viewport-height / 2

    p = @tween-position target-x, target-y, @speed
    @offset-x = p.x
    @offset-y = p.y

  tween-position: (x, y, speed) ->
    px = @_px or x
    py = @_py or y
    qx = @_qx or px
    qy = @_qy or py

    px1 = lerp px, x, speed
    py1 = lerp py, y, speed
    qx1 = lerp qx, px1, speed
    qy1 = lerp qy, py1, speed

    @_px = px1
    @_py = py1
    @_qx = qx1
    @_qy = qy1
    {x: qx1, y: qy1}
