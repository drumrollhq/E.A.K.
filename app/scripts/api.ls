$.ajax-setup {
  xhr-fields: with-credentials: true
}

GET = 'GET'
POST = 'POST'
DELETE = 'DELETE'

root = if window.location.host.match /eraseallkittens\.com/
  'http://api.eraseallkittens.com'
else
  'http://localhost:3000'

no-op = -> null

post-json = ({url, data, success, error, cb}) ->
  if cb?
    success = (data) -> cb null, data
    error = (err) -> cb err, null

  $.ajax {
    method: POST
    content-type: 'application/json'
    url: url
    data: JSON.stringify data
    success: success
    error: error
  }

module.exports = api = {
  root: root
  version: 'v1'
  url: (...segments) -> "#{api.root}/#{api.version}/#{(flatten segments).join '/'}"

  users:
    url: (...segments) -> api.url 'users', flatten segments

    me: (cb = no-op) ->
      $.ajax {
        method: GET
        url: api.users.url 'me'
        data-type: \json
        success: (data) -> cb null data
        error: (xhr, status, err) -> cb err
      }

  sessions:
    url: (...segments) -> api.url 'sessions', flatten segments

    create: (data, cb = no-op) ->
      post-json {
        url: api.sessions.url!
        data: data
        success: (session) -> cb session
        error: -> cb null
      }

    checkin: (session-id, event-ids, cb = no-op) ->
      post-json {
        url: api.sessions.url session-id
        data: ids: event-ids
        cb: cb
      }

    stop: (id, async = true, cb = no-op) ->
      $.ajax {
        method: DELETE
        url: api.sessions.url id
        async: async
        success: cb
      }

    create-event: (session-id, type, data, has-duration, cb = no-op) ->
      post-json {
        url: api.sessions.url session-id, 'events'
        data: {type, data, has-duration}
        cb: cb
      }

    stop-event: (session-id, event-id, cb = no-op) ->
      $.ajax {
        method: DELETE
        url: api.sessions.url session-id, 'events', event-id
        cb: cb
      }

    update-event: (session-id, event-id, data, cb = no-op) ->
      post-json {
        url: api.sessions.url session-id, 'events', event-id
        data: data
        cb: cb
      }
}
