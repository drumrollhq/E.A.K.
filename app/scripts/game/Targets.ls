map = (fn, arr) --> _.map arr, fn

parse-targets = ->
  it / ',' |> map (
    -> it.trim! / ' ' |> map (
      -> it.trim! |> parse-float))
  |> map (-> x: it.0, y: it.1)

module.exports = (container, targets) -->
  targets = parse-targets targets

  cx = container.width / 2
  cy = container.height / 2

  for target in targets
    el = $ '<div></div>'
      ..add-class 'entity entity-target'
      ..attr 'data-sensor', true
      ..attr 'data-id', 'ENTITY_TARGET'
      ..css left: target.x + cx, top: target.y + cy
      ..append-to container.el
