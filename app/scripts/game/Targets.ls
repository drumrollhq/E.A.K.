map = (fn, arr) --> _.map arr, fn

const available-kittens = 5

parse-targets = ->
  it / ',' |> map (
    -> it.trim! / ' ' |> map (
      -> it.trim! |> parse-float))
  |> map (-> x: it.0, y: it.1)

random-kitten = ->
  "url('/content/kittens/kitten-#{ (Math.random! * available-kittens |> Math.floor) + 1 }.gif')"

module.exports = (container, targets) -->
  targets = parse-targets targets

  cx = container.width / 2
  cy = container.height / 2

  for target in targets
    el = $ '<div></div>'
      ..add-class 'entity entity-target'
      ..attr 'data-sensor', true
      ..attr 'data-id', 'ENTITY_TARGET'
      ..attr 'data-target', true
      ..css do
        left: target.x + cx
        top: target.y + cy
        background-image: random-kitten!
      ..append-to container.el
