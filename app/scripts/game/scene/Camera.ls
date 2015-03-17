range = (min1, max1, min2, max2, x) -->
  n = (x - min1) / (max1 - min1)
  min2 + (n * (max2 - min2))

constrain = (min, max, x) -->
  | x < min => min
  | x > max => max
  | otherwise => x

lerp = (a, b, x) --> a + x * (b - a)

duration-to-speed = (duration) -> (Math.E * Math.E * 16.6) / duration

module.exports = class Camera
  @VISUAL_DEBUG = false
  @TARGET_VEL_SCALE_X = 80
  @TARGET_VEL_SCALE_Y = 0
  @MAX_BOUND_X = 400px
  @MAX_BOUND_Y = 150px
  @PAD = 20px

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
    @offset-x = p.x .|. 0
    @offset-y = p.y .|. 0

  dbg: new PIXI.Graphics!

  get-target-position: ->
    if @_tracking and @_tracking.v
      vel-adj-x = @_tracking.v.x * Camera.TARGET_VEL_SCALE_X
      vel-adj-y = @_tracking.v.y * Camera.TARGET_VEL_SCALE_Y
    else vel-adj-x = vel-adj-y = 0

    current-camera-x = (@offset-x or @_subject-x) + @_viewport-width/2
    current-camera-y = (@offset-y or @_subject-y) + @_viewport-height/2
    box-width = Math.min Camera.MAX_BOUND_X, 0.8 * @_viewport-width
    box-height = Math.min Camera.MAX_BOUND_Y, 0.5 * @_viewport-height
    box-left = current-camera-x - box-width / 2
    box-top = current-camera-y - box-height / 2
    camera-target-x = @_subject-x + vel-adj-x
    camera-target-y = @_subject-y + vel-adj-y

    adjust-left = if camera-target-x < box-left
      camera-target-x - box-left - Camera.PAD
    else if camera-target-x > box-left + box-width
      camera-target-x - (box-left + box-width) + Camera.PAD
    else 0
    adjust-top = if camera-target-y < box-top
      camera-target-y - box-top - Camera.PAD
    else if camera-target-y > box-top + box-height
      camera-target-y - (box-top + box-height) + Camera.PAD
    else 0

    if Camera.VISUAL_DEBUG
      eak._stage.view.effects-layer.stage.add-child @dbg
      @dbg
        ..clear!
        ..line-style 3, 0xFF00FF .draw-ellipse @_subject-x, @_subject-y, 5, 5
        ..line-style 1, 0xFFFF00 .draw-ellipse current-camera-x, current-camera-y, 5, 5
        ..line-style 1, 0x00FFFF .draw-ellipse current-camera-x + vel-adj-x, current-camera-y + vel-adj-y, 8, 8
        ..line-style 3, 0x00FF00 .draw-rect box-left, box-top, box-width, box-height
        ..line-style 1, 0xFF0000 .draw-rect box-left + adjust-left, box-top + adjust-top, box-width, box-height
        ..line-style 1, 0xFF0000 .draw-rect camera-target-x - 5, camera-target-y - 5, 10, 10

    max-x = @scene-width - @_viewport-width
    max-y = @scene-height - @_viewport-height
    target-x = if @_lock-x? then @_lock-x
      else constrain 0, max-x, current-camera-x + adjust-left - @_viewport-width / 2
    target-y = if @_lock-y? then @_lock-y
      else constrain 0, max-y, current-camera-y + adjust-top - @_viewport-height / 2

    [target-x, target-y]

  start-edit-mode: (rect, duration, frame-driver) -> new Promise (resolve, reject) ~>
    @_editing = true
    @_edit-rect = rect
    @_normal-speed = @speed
    @speed = duration-to-speed duration

    sub = frame-driver.subscribe ~>
      @step!
      dx = @target-x - @offset-x
      dy = @target-y - @offset-y
      dist = dx * dx + dy * dy
      if dist < 10
        console.log 'REACHED TARGET'
        sub.unsubscribe!
        @speed = 1
        resolve!

  stop-edit-mode: (duration, frame-driver) -> new Promise (resolve, reject) ~>
    @_editing = false
    @_edit-rect = null
    @speed = duration-to-speed duration
    sub = frame-driver.subscribe ~>
      @step!
      dx = @target-x - @offset-x
      dy = @target-y - @offset-y
      dist = dx * dx + dy * dy
      if dist < 10
        console.log 'REACHED TARGET'
        sub.unsubscribe!
        @speed = @_normal-speed
        resolve!

  get-editing-position: ->
    const pad = 30px
    {top, left, height, width} = @_edit-rect
    target-x = if @_viewport-width/2 < 2*pad + width
      left - @_viewport-width/2 - pad
    else left - @_viewport-width*0.75 + width/2
    target-y = if @_viewport-height < 2*pad + height
      top - pad
    else top - @_viewport-height/2 + height/2
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
