require! {
  'animation/SpriteSheet'
  'game/actors/Player'
  'game/area/AreaLevel'
  'game/area/CameraScene'
  'game/area/background'
  'lib/channels'
  'logger'
}

$body = $ document.body

const edit-margin = 50px

create-level-container = (parent) ->
  $ '<div></div>'
    ..add-class 'area-level-container'
    ..append-to parent

create-blurred-bg = (parent, width, height) ->
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
    $ document.body .remove-class 'has-tutorial'

  render: ->
    @blurred-bg ?= create-blurred-bg @$el, (@model.get 'width'), (@model.get 'height')
    @update-size!
    @update-background!
    $ document.body .add-class 'playing playing-area hide-edit'

  level: -> @levels[@model.get 'playerLevel']

  set-save-stage: (stage) ->
    @save-stage = stage
    for level in @levels => level.set-save-stage stage

  switch-level-focus: (index) ->
    level = @levels[index]

    {x, y} = level.conf.player
    x += level.conf.x
    y += level.conf.y
    @player.origin <<< {x, y}

    level.activate!

    if level.conf.editable then $body.remove-class \hide-edit else $body.add-class \hide-edit

  is-editable: -> @level!.conf.editable

  add-levels: (stage) ->
    @level-container ?= create-level-container @$el
    @levels = @model.levels.map (level) -> new AreaLevel {level, stage}

    for level in @levels
      level.$el.append-to @level-container
      level.render!

  create-maps: ->
    @$el.css top: 0, left: 0, margin-top: 0, margin-left: 0
    for level in @levels => level.create-map!
    @resize!

  assemble-map: -> @levels |> map ( .map ) |> flatten

  initial-player-pos: ->
    {x, y} = @levels.0.conf.player
    x += @levels.0.conf.x
    y += @levels.0.conf.y
    {x, y}

  add-player: ->
    if @player? then return @player

    {x, y} = @initial-player-pos!
    @move {x, y}
    @player = player = new Player {x, y}
      ..$el.append-to @$el
      ..$el.attr id: "#{@el.id}-player"
      ..id = "#{@el.id}-player"

  add-targets: -> for level in @levels => level.add-targets!
  add-actors: -> for level in @levels => level.add-actors!

  remove: ->
    for level in @levels => level.remove!
    @player.remove!
    background.clear!
    super!

  start-editor: ->
    if @model.get 'editing' then return
    @model.set 'editing' true

    channels.game-commands.publish command: 'edit-start'
    @edit-event = null
    logger.start 'edit', {}, .then (event) -> @edit-event = event.id

    if @level!.conf.reset-player-on-edit then @player.reset!
    @player.draw!

    level = @level!

    @focus-level-for-editor!
    level.start-editor!
    level.once 'stop-editor' ~> @trigger 'stop-editor'

  stop-editor: ->
    if @edit-event
      logger.update @edit-event, html: (editor.get \html), css: (editor.get \css) .then -> logger.stop @edit-event

    channels.game-commands.publish command: 'edit-stop'
    @unfocus-level-for-editor! .then ~>
      @model.set 'editing' false
      @clear-position!
      @create-maps!
      @model.build-map!

  focus-level-for-editor: ->
    level = @level!
    @focus-level level

    pos = @level-edit-pos level
    @transition-to pos.x, pos.y .then ~>
      @clear-position!

      @set-edit-css level
      @override-resize!

  unfocus-level-for-editor: ->
    level = @level!
    @unfocus-level level

    @remove-edit-css!
    @restore-resize!

    pos = @level-edit-pos level
    @set-transform pos.x, pos.y
    Promise.delay 0 .then ~>
      {x, y} = @get-position @player.p.x, @player.p.y
      unless @scrolling.x then x = 0
      unless @scrolling.y then y = 0
      @transition-to -x, -y

  focus-level: (level) ->
    for other-level in @levels when other-level isnt level => other-level.hide!
    @blurred-bg.add-class 'active'
    level.$el
      ..add-class 'focused'
      ..css {
        background-image: "url(#{@model.get 'background'})"
        background-size: "#{@model.get 'width'}px #{@model.get 'height'}px"
        background-position: "#{-level.conf.x}px #{-level.conf.y}px"
      }

  unfocus-level: (level) ->
    for lvl in @levels => lvl.show!
    @blurred-bg.remove-class 'active'
    level.$el.remove-class 'focused'

  level-edit-pos: (level) ->
    win-width = @$window.width!
    win-height = @$window.height!
    el-width = level.conf.width + 2 * edit-margin
    el-height = level.conf.height + 2 * edit-margin
    margin-top = parse-float @$el.css 'margin-top'
    margin-left = parse-float @$el.css 'margin-left'

    if margin-left is 0 then x = win-width/2 else x = - margin-left
    if margin-top is 0 then y = 0 else y = -win-height/2 - margin-top

    x += edit-margin - level.conf.x
    y += edit-margin - level.conf.y

    width = win-width / 2
    height = win-height
    if el-height < height then y += (height - el-height) / 2
    if el-width < width then x += (width - el-width) / 2

    {x, y}

  set-edit-css: (level) ->
    @$el.css {
      width: '100%'
      height: '100%'
      min-width: level.conf.width + 2 * edit-margin
      min-height: level.conf.height + 2 * edit-margin
      top: 0
      left: 0
      margin-top: 0
      margin-left: 0
      background: 'transparent'
    }

    @$el.parent!.css {
      left: '50%'
      width: '50%'
      overflow: 'auto'
    }

  remove-edit-css: ->
    @update-size!
    @update-background!
    @$el.parent!
      ..scroll-top 0
      ..scroll-left 0
    @$el.css min-width: '', min-height: '', background-position: '0 0'
    @$el.parent!.css left: '', width: '', overflow: ''
    @$el.children!.css margin-top: '', margin-left: ''

  override-resize: ->
    @normal-resize = @resize
    @resize = @edit-resize
    @resize!

  restore-resize: ->
    @resize = @normal-resize
    @resize!

  transition-to: (x, y) -> new Promise (resolve, reject) ~>
    finish = (e) ~>
      if e and e.target isnt @el then return
      console.log @$el
      @$el.off prefixed.transition-end, finish
      @$el.remove-class 'trans'
      clear-timeout finish-timeout # TODO: remove this. Hack.
      resolve!

    @$el.add-class 'trans'
    @$el.on prefixed.transition-end, finish
    finish-timeout = set-timeout finish, 700

    @set-transform x, y

  get-edit-margins: ->
    level = @level!

    width = @$window.width! / 2
    height = @$window.height!
    el-width = level.conf.width + 2 * edit-margin
    el-height = level.conf.height + 2 * edit-margin
    el-pos-x = level.conf.x - edit-margin
    el-pos-y = level.conf.y - edit-margin

    if width < el-width
      margin-left = -el-pos-x
    else
      margin-left = (width - el-width ) / 2 - el-pos-x

    if height < el-height
      margin-top = -el-pos-y
    else
      margin-top = (height - el-height) / 2 - el-pos-y

    {margin-top, margin-left}

  edit-resize: ->
    children = @$el.children!
    margins = @get-edit-margins!
    children.css margins
    @$el.css 'background-position', "#{margins.margin-left}px #{margins.margin-top}px"

  setup-sprite-sheets: ->
    Promise.map (@$el.find '[data-sprite]' .to-array!), SpriteSheet.create

  update-size: -> @set-size (@model.get 'width'), (@model.get 'height')

  update-background: ->
    @$el.css {
      background-image: "url(#{@model.get 'background'}?_v=#{EAKVERSION})"
      background-size: "#{@model.get 'width'}px #{@model.get 'height'}px"
      background-position: '0 0'
    }

  get-player-level: ->
    {x, y} = @player.p
    for level, i in @levels
      if level.contains x, y then return i
