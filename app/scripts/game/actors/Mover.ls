require! {
  'game/actors/Actor'
  'lib/math/Path'
  'lib/math/Vector'
  'lib/parse'
}

module.exports = class Mover extends Actor
  @from-el = ($el, [speed = '2000', repeat = 'alternate', ease = 'linear'], offset = {x: 0, y: 0}, store, area-view) ->
    speed = parse-float speed
    path = $el.attr 'data-path'
      |> parse.to-list _, ','
      |> map parse.to-coordinates

    new this {
      speed: speed
      repeat: repeat
      path: path
      el: $el.0
      offset: offset
      ease: ease
      area-view: area-view
    }

  physics: {
    data:
      dynamic: true
      ignore-others: true
  }

  mapper-ignore: false

  initialize: (start = {speed: 2, repeat: 'alternate', path: [[0, 0] [100 100]]}) ->
    super start
    offset-vector = new Vector @offset
    path = start.path |> map ([x, y]) -> offset-vector .add new Vector x, y
    @path = new Path path, start.repeat is \alternate, start.ease
    @total-time = 0
    @speed = start.speed

  on-prepare: ->
    @$el.css left: @offset.x, top: @offset.y

  step: (dt) ->
    @total-time += dt
    @p <<< @path.at @total-time * @speed .{x, y}
