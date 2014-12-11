require! {
  'channels'
  'game/Player'
  'game/area/AreaLevel'
  'game/renderer/CameraScene'
}

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

  render: ->
    @update-size!
    @update-background!
    $ document.body .add-class \playing

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

  update-size: -> @set-size (@model.get 'width'), (@model.get 'height')

  update-background: ->
    @$el.css {
      background-image: "url(#{@model.get 'background'})"
      background-size: "#{@model.get 'width'}px #{@model.get 'height'}px"
    }
