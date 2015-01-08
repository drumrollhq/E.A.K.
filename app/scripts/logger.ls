require! 'api'
const dt = 15000ms

module.exports = {
  setup: (missing-features, cb = -> null) ->
    # Send session data:
    first-path = window.location.pathname.replace /^\//, '' .split '/' .0
    if first-path in window.LANGUAGES then lang = first-path else lang = 'default'
    data = {
      platform:
        browser:
          name: platform.name or 'Unknown'
          version: platform.version or 'Unknown'
          engine: platform.layout or 'Unknown'
        os:
          name: platform.os.family or 'Unknown'
          version: platform.os.version or 'Unknown'
        device:
          name: platform.product or 'Unknown'
          manufacturer: platform.manufacturer or 'Unknown'

      dimensions:
        screen:
          width: window.screen.width
          height: window.screen.height
        window:
          width: $ window .width!
          height: $ window .height!

      ua: window.navigator.user-agent
      device-pixel-ratio: window.device-pixel-ratio
      browser-locale: window.navigator.language
      game-locale: lang
      entry-hash: window.location.hash
      domain: window.location.host
      missing-features: missing-features or false
    }

    session <~ api.sessions.create data
    if session?
      @session = session
      @session.active-events = []
      @setup-checkin-loop!
      @setup-cleanup!

    cb!

  setup-checkin-loop: ->
    unless @session? then return
    url = "sessions/#{@session.id}"
    <~ set-interval _, dt
    api.sessions.checkin @session.id, @session.active-events

  setup-cleanup: ->
    unless @session? then return
    is-clean = false
    cleanup = !~>
      if is-clean then return
      api.sessions.stop @session.id, false

    $ window
      ..on 'unload' ~>
        cleanup!
      ..on 'beforeunload' ~>
        cleanup!

  send-event: (type, data, has-duration, cb = -> null) ->
    unless @session? then return cb id: null
    if ga? then ga 'send' {
      hit-type: 'event'
      event-category: type
      event-action: if has-duration then 'start' else 'log'
    }

    err, event <~ api.sessions.create-event @session.id, type, data, has-duration
    if err then return cb id: null
    if has-duration then @session.active-events[*] = event.id
    cb event

  log: (type, data = {}, cb) -> @send-event type, data, false, cb
  start: (type, data = {}, cb) -> @send-event type, data, true, cb

  stop: (id) ->
    console.log @, @session
    unless @session? and id? then return
    @session.active-events .= filter (it) -> it isnt id
    api.sessions.stop-event @session.id, id

  update: (id, data, cb) ->
    unless @session and id? then return cb!
    api.sessions.update-event @session.id, @event-id, data, -> cb!
}

