require! 'game/mediator'

module.exports = keys = {
  left: false
  right: false
  jump: false
}

triggers = {
  left:
    keys: <[ left a ]>
    exclude: <[ right ]>

  right:
    keys: <[ right d ]>
    exclude: <[ left ]>

  jump:
    keys: <[ up w space ]>
    exclude: []
}

listen = (name, trigger) ->
  console.log name, "keydown:#{trigger.keys.join ','}"
  mediator.on "keydown:#{trigger.keys.join ','}", ->
    keys[name] = true
    [keys[ex] = false for ex in trigger.exclude]

  mediator.on "keyup:#{trigger.keys.join ','}", ->
    keys[name] = false

for name, trigger of triggers => listen name, trigger
