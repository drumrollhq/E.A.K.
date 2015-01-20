$.ajax-setup {
  xhr-fields: with-credentials: true
}

GET = 'GET'
POST = 'POST'
DELETE = 'DELETE'

root = if window.location.host.match /eraseallkittens\.com/
  '//api.eraseallkittens.com'
else
  '//localhost:3000'

no-op = -> null

json-req = (method, url, data) -->
  Promise.resolve $.ajax {
    method: method
    url: url
    data: JSON.stringify data if data?
    content-type: 'application/json'
  }

post-json = (url, data) -> json-req POST, url, data
get-json = (url, data) -> json-req GET, url, data
delete-json = (url, data) -> json-req DELETE, url, data

module.exports = api = {
  root: root
  version: 'v1'
  url: (...segments) ->
    segments = flatten segments
    if typeof (last segments) is 'object'
      query = '?' + $.param last segments
      segments = initial segments
    else query = ''
    "#{api.root}/#{api.version}/#{segments.join '/'}#{query}"

  users:
    url: (...segments) -> api.url 'users', flatten segments
    me: -> get-json api.users.url 'me'
    usernames: (query) -> get-json api.users.url 'usernames', query

  auth:
    url: (...segments) -> api.url 'auth', flatten segments
    logout: -> get-json api.auth.url 'logout'
    login: (username, password) -> post-json (api.auth.url 'login'), {username, password}
    register: (user) -> post-json (api.auth.url 'register'), user

  games:
    url: (...segments) -> api.url 'games', flatten segments
    create: (data) -> post-json api.games.url!, data
    get: (id) -> get-json api.games.url id

  sessions:
    url: (...segments) -> api.url 'sessions', flatten segments
    create: (data) -> post-json api.sessions.url!, data
    checkin: (session-id, event-ids) -> post-json (api.sessions.url session-id), ids: event-ids
    stop: (id, async = true) -> Promise.resolve $.ajax {
      method: DELETE
      url: api.sessions.url id
      async: async
    }

    create-event: (session-id, type, data, has-duration) ->
      post-json (api.sessions.url session-id, 'events'), {type, data, has-duration}

    stop-event: (session-id, event-id) ->
      delete-json api.sessions.url session-id, 'events', event-id

    update-event: (session-id, event-id, data) ->
      post-json (api.sessions.url session-id, 'events', event-id), data
}
