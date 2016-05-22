require! 'hindquarters'
const dt = 15000ms

module.exports = {
  setup: (missing-features, logged-in-user) ->
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
      domain: if window.location.port is \5275 then \ELECTRON_APP else window.location.host
      missing-features: missing-features or false
      logged-in-user: logged-in-user or false
    }

    hindquarters.sessions.create data
      .then (session) ~>
        if session?
          @session = session
          @session.active-events = []
          @setup-checkin-loop!
      .catch ~> null

  setup-checkin-loop: ->
    unless @session? then return
    url = "sessions/#{@session.id}"
    <~ set-interval _, dt
    hindquarters.sessions.checkin @session.id, ids: @session.active-events

  send-event: (type, data, has-duration) ->
    console.time-stamp type
    unless @session? then return Promise.resolve id: null
    if ga? then ga 'send' {
      hit-type: 'event'
      event-category: type
      event-action: if has-duration then 'start' else 'log'
    }

    hindquarters.sessions.events.create @session.id, {type, data, has-duration}
      .tap (event) ~>
        if has-duration then @session.active-events[*] = event.id
      .catch -> Promise.resolve id: null

  log: (type, data = {}) -> @send-event type, data, false
  start: (type, data = {}) -> @send-event type, data, true

  stop: (id) ->
    unless @session? and id? then return
    @session.active-events .= filter (it) -> it isnt id
    hindquarters.sessions.events.stop @session.id, id

  update: (id, data) ->
    unless @session and id? then return Promise.resolve!
    hindquarters.sessions.events.update @session.id, @event-id, data
}

