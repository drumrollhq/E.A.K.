require! 'lib/channels'

module.exports = keys = {
  left: false
  right: false
  jump: false
  reset: ~>
    for key, value of keys when typeof value isnt \function
      keys[key] = false
}

triggers = {
  left:
    keys: <[ left a h ]>
    exclude: <[ right ]>

  right:
    keys: <[ right d l ]>
    exclude: <[ left ]>

  up:
    keys: <[ up w k ]>
    exclude: <[ down ]>

  down:
    keys: <[ down s j ]>
    exclude: <[ up ]>

  jump:
    keys: <[ up w space k ]>
    exclude: []
}

listen = (name, trigger) ->
  channels.key-down.filter ( .key in trigger.keys ) .subscribe ->
    keys[name] = true
    [keys[ex] = false for ex in trigger.exclude]

  channels.key-up.filter ( .key in trigger.keys ) .subscribe ->
    keys[name] = false

for name, trigger of triggers => listen name, trigger
