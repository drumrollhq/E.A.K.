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

json-req = (method, {url, data, success, error, cb}) -->
  if cb?
    success = (data) -> cb null, data
    error = (xhr, _, err) -> if xhr.response-JSON then cb that, null else cb err, null

  $.ajax {
    method: method
    content-type: 'application/json'
    url: url
    data: JSON.stringify data if data?
    success: success
    error: error
  }

post-json = json-req POST
get-json = json-req GET

module.exports = api = {
  root: root
  version: 'v1'
  url: (...segments) ->
    segments = flatten segments
    if typeof (last segments) isnt 'string'
      query = '?' + $.param last segments
      segments = initial segments
    else query = ''
    "#{api.root}/#{api.version}/#{segments.join '/'}#{query}"

  users:
    url: (...segments) -> api.url 'users', flatten segments
    me: (cb = no-op) -> get-json cb: cb, url: api.users.url 'me'

  auth:
    url: (...segments) -> api.url 'auth', flatten segments
    logout: (cb = no-op) -> get-json cb: cb, url: api.auth.url 'logout'

    login: (username, password, cb = no-op) ->
      post-json {
        url: api.auth.url 'login'
        data: {username, password}
        cb: cb
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
