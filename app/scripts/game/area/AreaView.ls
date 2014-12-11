require! {
  'channels'
  'game/Player'
  'game/area/AreaLevel'
  'game/renderer/CameraScene'
  'animation/SpriteSheet'
}

$body = $ document.body

create-level-container = (parent) ->
  $ '<div></div>'
    ..add-class 'area-level-container'
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
    @update-size!
    @update-background!
    $ document.body .add-class 'playing playing-area hide-bar'

  switch-level-focus: (index) ->
    level = @levels[index]

    {x, y} = level.conf.player
    x += level.conf.x
    y += level.conf.y
    @player.origin <<< {x, y}

    if level.conf.editable then $body.remove-class \hide-bar else $body.add-class \hide-bar

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

  setup-sprite-sheets: (done) ->
    async.each (@$el.find '[data-sprite]'), SpriteSheet.create, done

  update-size: -> @set-size (@model.get 'width'), (@model.get 'height')

  update-background: ->
    @$el.css {
      background-image: "url(#{@model.get 'background'})"
      background-size: "#{@model.get 'width'}px #{@model.get 'height'}px"
    }

  get-player-level: ->
    {x, y} = @player.p
    for level, i in @levels
      if level.contains x, y then return i
