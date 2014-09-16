const dt = 15000ms

no-op = -> null
post-json = ({url, data, success, error}) ->
  $.ajax {
    method: \POST
    content-type: 'application/json'
    url: url
    data: JSON.stringify data
    success: success
    error: error
  }

create-session = (data, cb) ->
  post-json {
    url: '/api/v1/sessions'
    data: data
    success: (session) -> cb session
    error: ->
      console.error arguments
      cb id: 'error', user: 'error'
  }

module.exports = {
  setup: (missing-features, cb = no-op) ->
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

    session <~ create-session data
    @session = session
    @session.active-events = []
    @setup-checkin-loop!
    @setup-cleanup!
    cb!

  setup-checkin-loop: ->
    url = "/api/v1/sessions/#{@session.id}"
    <~ set-interval _, dt
    post-json {
      url: url
      data:
        ids: @session.active-events
    }

  setup-cleanup: ->
    is-clean = false
    cleanup = !~>
      if is-clean then return
      $.ajax {
        type: \DELETE
        url: "/api/v1/sessions/#{@session.id}"
        async: false
        success: -> is-clean := true
      }

    $ window
      ..on 'unload' ~>
        cleanup!
      ..on 'beforeunload' ~>
        cleanup!

  send-event: (type, data, has-duration, cb) ->
    if ga? then ga 'send' {
      hit-type: 'event'
      event-category: type
      event-action: if has-duration then 'start' else 'log'
    }

    post-json {
      url: "/api/v1/sessions/#{@session.id}/events"
      data: {type, data, has-duration}
      success: (event) ~>
        if has-duration then @session.active-events[*] = event.id
        cb event
      error: ->
        console.error arguments
        cb {id: 'error'}
    }

  log: (type, data = {}, cb = no-op) -> @send-event type, data, false, cb
  start: (type, data = {}, cb = no-op) -> @send-event type, data, true, cb

  stop: (id) ->
    @session.active-events .= filter (it) -> it isnt id
    $.ajax {
      type: \DELETE
      url: "/api/v1/sessions/#{@session.id}/events/#{id}"
    }

  update: (id, data, cb) ->
    console.log data, JSON.stringify data
    post-json {
      url: "/api/v1/sessions/#{@session.id}/events/#{id}"
      data: data
      success: -> cb!
      error: -> cb!
    }
}

