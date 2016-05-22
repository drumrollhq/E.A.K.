module.exports = timer = (delay) ->
  var resolve, timeout, start-time

  pr = new Promise (_res) -> resolve := _res
  ticking = false

  start = ->
    ticking := true
    start-time := performance.now!
    timeout := set-timeout resolve, delay

  stop = ->
    ticking := false
    clear-timeout timeout
    elapsed = performance.now! - start-time
    delay := Math.max 0, delay - elapsed

  is-ticking = ->
    ticking and not pr.is-fulfilled!

  pr <<< {start, stop, is-ticking}
  pr
