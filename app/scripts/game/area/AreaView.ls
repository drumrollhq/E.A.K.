require! {
  'animation/SpriteSheet'
  'channels'
  'game/Player'
  'game/area/AreaLevel'
  'game/event-loop'
  'game/level/background'
  'game/renderer/CameraScene'
  'logger'
}

$body = $ document.body

const edit-margin = 50px
const bar-height = 50px

create-level-container = (parent) ->
  $ '<div></div>'
    ..add-class 'area-level-container'
    ..append-to parent

create-blurred-bg = (parent, width, height) ->
  console.log background
  $ '<div></div>'
    ..add-class 'area-level-blurred-bg'
    ..css {
      background-image: background.current-background.value
      width: width
      height: height
    }
    ..append-to parent

module.exports = class AreaView extends CameraScene
  tag-name: 'div'
  class-name: 'area-view'

  (options) ->
    options.track-channel = channels.player-position
    super options

  initialize: (options) ->
    super options
    @model.on 'change:playerLevel', (_, level) ~> @switch-level-focus level

  render: ->
    @blurred-bg ?= create-blurred-bg @$el, (@model.get 'width'), (@model.get 'height')
    @update-size!
    @update-background!
    $ document.body .add-class 'playing playing-area hide-bar'

  level: -> @levels[@model.get 'playerLevel']

  switch-level-focus: (index) ->
    level = @levels[index]

    {x, y} = level.conf.player
    x += level.conf.x
    y += level.conf.y
    @player.origin <<< {x, y}

    if level.conf.editable then $body.remove-class \hide-bar else $body.add-class \hide-bar

  is-editable: -> @level!.conf.editable

  add-levels: ->
    @level-container ?= create-level-container @$el
    @levels = @model.levels.map (level) -> new AreaLevel level

    for level in @levels
      level.$el.append-to @level-container
      level.render!

  create-map: ->
    @$el.css top: 0, left: 0, margin-top: 0, margin-left: 0
    nodes = @levels |> map ( .create-map! ) |> flatten
    @resize!
    nodes

  add-player: (player-conf, set-pos = true) ->
    if @player? then return @player

    {x, y} = @levels.0.conf.player
    x += @levels.0.conf.x
    y += @levels.0.conf.y

    @move {x, y}

    @player = player = new Player {x, y}
      ..$el.append-to @$el
      ..$el.attr id: "#{@el.id}-player"
      ..id = "#{@el.id}-player"

  add-targets: -> for level in @levels => level.add-targets!

  start-editor: ->
    if @model.get 'editing' then return
    @model.set 'editing' true

    channels.game-commands.publish command: 'edit-start'
    edit-event = null
    logger.start 'edit', {}, (event) -> edit-event := event.id

    if @level!.conf.reset-player-on-edit then @player.reset!
    event-loop.pause!
    @player.draw!

    level = @level!

    @focus-level!
    level.start-editor!

  focus-level: (cb = -> null) ->
    level = @level!
    for other-level in @levels when other-level isnt level => other-level.hide!
    @blurred-bg.add-class 'active'
    level.$el
      ..add-class 'focused'
      ..css {
        background-image: "url(#{@model.get 'background'})"
        background-size: "#{@model.get 'width'}px #{@model.get 'height'}px"
        background-position: "#{-level.conf.x}px #{-level.conf.y}px"
      }

    <~ @transition-level-focus!
    @clear-position!

    @$el.css {
      width: '100%'
      height: '100%'
      min-width: level.conf.width + 2 * edit-margin
      min-height: level.conf.height + 2 * edit-margin + bar-height
      top: 0
      left: 0
      margin-top: 0
      margin-left: 0
    }

    @$el.parent().css {
      left: '50%'
      width: '50%'
      overflow: 'auto'
    }

    @override-resize!
    cb!

  transition-level-focus: (cb = -> null) ->
    level = @level!
    win-width = @$window.width!
    win-height = @$window.height!
    el-width = level.conf.width + 2 * edit-margin
    el-height = level.conf.height + 2 * edit-margin
    margin-top = parse-float @$el.css 'margin-top'
    margin-left = parse-float @$el.css 'margin-left'
    console.log {win-width, win-height, margin-top, margin-left, el-width, el-height}

    if margin-left is 0
      x = win-width / 2
    else
      x = margin-left

    if margin-top is 0
      y = 0
    else
      y = -win-height / 2 - margin-top

    x += edit-margin - level.conf.x
    y += edit-margin - level.conf.y + bar-height

    width = win-width / 2
    height = win-height - bar-height
    if el-height < height then y += (height - el-height) / 2
    if el-width < width then x += (width - el-width) / 2

    finish = (e) ~>
      unless e.target is @el then return
      console.log 'transitionend', arguments
      @$el.off 'transitionend', finish
      @$el.remove-class 'trans'
      cb!
    @$el.add-class 'trans'
    @$el.on prefixed.transition-end, finish

    @set-transform x, y

  override-resize: ->
    @normal-resize = @resize
    @resize = @edit-resize
    @resize!

  get-edit-margins: ->
    level = @level!

    width = @$window.width! / 2
    height = @$window.height! - bar-height
    el-width = level.conf.width + 2 * edit-margin
    el-height = level.conf.height + 2 * edit-margin
    el-pos-x = level.conf.x - edit-margin
    el-pos-y = level.conf.y - edit-margin

    if width < el-width
      margin-left = -el-pos-x
    else
      margin-left = (width - el-width ) / 2 - el-pos-x

    if height < el-height
      margin-top = -el-pos-y + bar-height
    else
      margin-top = (height - el-height) / 2 - el-pos-y + bar-height

    {margin-top, margin-left}

  edit-resize: ->
    children = @$el.children!
    margins = @get-edit-margins!
    children.css margins
    @$el.css 'background-position', "#{margins.margin-left}px #{margins.margin-top}px"

  setup-sprite-sheets: (done) ->
    async.each (@$el.find '[data-sprite]'), SpriteSheet.create, done

  update-size: -> @set-size (@model.get 'width'), (@model.get 'height')

  update-background: ->
    @$el.css {
      background-image: "url(#{@model.get 'background'})"
      background-size: "#{@model.get 'width'}px #{@model.get 'height'}px"
      background-position: '0 0'
    }

  get-player-level: ->
    {x, y} = @player.p
    for level, i in @levels
      if level.contains x, y then return i
