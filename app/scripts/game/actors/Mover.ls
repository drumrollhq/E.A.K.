require! {
  'game/actors/Actor'
  'lib/math/Path'
  'lib/math/Vector'
  'lib/parse'
}

module.exports = class Mover extends Actor
  @from-el = ($el, [speed = '2000', repeat = 'alternate', ease = 'linear'], offset = {x: 0, y: 0}) ->
    speed = parse-float speed
    path = $el.attr 'data-path'
      |> parse.to-list _, ','
      |> map parse.to-coordinates

    new Mover {
      x: 0
      y: 0
      speed: speed
      repeat: repeat
      path: path
      el: $el.0
      offset: offset
      ease: ease
    }

  physics: {
    data:
      ignore-others: true
  }

  initialize: (start = {x: 0, y: 0, speed: 2, repeat: 'alternate', path: [[0, 0] [100 100]]}) ->
    super start
    offset-vector = new Vector @offset
    path = start.path |> map ([x, y]) -> offset-vector .add new Vector x, y
    @path = new Path path, start.repeat is \alternate, start.ease
    window.mpath = @path
    @speed = start.speed
    @total-time = 0

  step: (dt) ->
    @total-time += dt
    @p <<< @path.at @total-time * @speed .{x, y}
