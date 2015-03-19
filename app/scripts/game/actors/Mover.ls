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
    offset-vector = new Vector 0 0 # @offset
    path = start.path |> map ([x, y]) -> offset-vector .add new Vector x, y
    @path = new Path path, start.repeat is \alternate, start.ease
    @total-time = 0
    @speed = start.speed
    @$el.css top: 0, left: 0

  on-prepare: ->
    @x = @width/2
    @y = @height/2

  step: (dt) ->
    @total-time += dt
    @p <<< @path.at @total-time * @speed .{x, y}
    @p.x += @offset.x
    @p.y += @offset.y
