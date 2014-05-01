no-op = -> null

send = (url, data = {}, cb = no-op) ->
  $.ajax {
    method: \POST
    url: "api/#url"
    data-type: 'json'
    content-type: 'application/json'
    data: JSON.stringify data
    success: (event) -> cb event
    error: -> console.error arguments
  }

const dt = 5000ms
active-events = {}
default-parent = undefined

module.exports = {
  log: (type, data = {}, cb = no-op) ->
    <- set-timeout _, 0
    parent-id = if data.parent?
      data.parent
    else if default-parent?
      default-parent
    else undefined

    delete data.parent
    event = {type, parent-id, data, version: window.EAKVERSION}
    send 'events', event, cb

  start: (type, data, cb = no-op) ->
    event <- module.exports.log type, data
    active-events[event.id] = event
    poll = ->
      <- set-timeout _, dt
      if event.stopped? then return
      nev <- send "events/#{event.id}/checkin", dt: dt / 1000
      event <<< nev
      poll!

    event.stop = ->
      event.stopped = true
      poll := no-op
    poll!

    cb event

  stop: (id) -> active-events[id].stop!
  event: (id) -> active-events[id]

  set-default-parent: (id) ->
    console.log 'set-default-parent' id
    default-parent := id
}
