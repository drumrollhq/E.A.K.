get-positions = (info, cm) ->
  p0 = cm.pos-from-index 0

  pos =
    start:
      outer: p0
      inner: p0
    end:
      outer: p0
      inner: p0

  no-start = no-end = false

  if info.open-tag isnt undefined
    pos.start.outer = cm.pos-from-index info.open-tag.start
    pos.start.inner = cm.pos-from-index info.open-tag.end
  else if info.start isnt undefined
    pos.start.inner = pos.start.outer = cm.pos-from-index info.start
  else
    no-start = true

  if info.close-tag isnt undefined
    pos.end.outer = cm.pos-from-index info.close-tag.end
    pos.end.inner = cm.pos-from-index info.close-tag.start
  else if info.end isnt undefined
    pos.end.inner = pos.end.outer = cm.pos-from-index info.end
  else
    no-end = true

  if no-start and not no-end
    pos.start = pos.end
  else if no-end and not no-start
    pos.end = pos.start

  if no-start and no-end
    others = <[html cssBlock cssSelector cssProperty cssValue name]>

    for other in others
      if info[other] isnt undefined
        ref = info[other]
        break

    pos.start.outer = pos.start.inner = cm.pos-from-index ref.start
    pos.end.outer = pos.end.inner = cm.pos-from-index ref.end

  return pos

# TODO: Find a less horrid way of doing this:
get-allowed-fn = (cond) -> new Function 'code', '$', 'extras', 'return ' + cond

module.exports = {
  get-positions
  get-allowed-fn
}
