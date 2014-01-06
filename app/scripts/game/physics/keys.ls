module.exports = keys = {
  left: false
  right: false
  jump: false
}

document.add-event-listener 'keydown', (e) ->
  switch e.which
  | 39, 68 =>
    keys.right = true
    keys.left = false
  | 37, 65 =>
    keys.left = true
    keys.right = false
  | 38, 87, 32 => keys.jump = true

document.add-event-listener 'keyup', (e) ->
  switch e.which
  | 39, 68 => keys.right = false
  | 37, 65 => keys.left = false
  | 38, 87, 32 => keys.jump = false
