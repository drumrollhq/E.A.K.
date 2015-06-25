require! {
  'lib/set-at'
}

req-json = (method, url, options, body) ->
  if options
    url += '?' + $.param options

  Promise
    .resolve do
      xhr = $.ajax {
        method: method
        url: url
        data: JSON.stringify body if body?
        content-type: 'application/json'
        timeout: 10_000ms
      }
      xhr.url = url
      xhr
    .catch (e) ->
      if e.response-JSON then throw that
      else throw e

methods = GET: \GET, POST: \POST, PUT: \PUT, DELETE: \DELETE, DEL: \DELETE

flatten-routes = (obj, url = "#root/") ->
  routes = {}
  for key, value of obj
    if typeof value is \object
      routes <<< flatten-routes value, "#{url}#{key}/"
    else if typeof value is \string
      routes[value] = {url, method: methods[key]}

  routes

get-handler = (spec, route) -> (...args) ->
  if spec.param-list
    params = {[param, args.shift!] for param in spec.param-list}

  if spec.options
    options = args.shift!

  if spec.body
    body = args.shift!

  # TODO: Add websocket option, falling back to http requests:
  http route.method, route.url, params, options, body

http = (method, url, params, options, body) ->
  if params then for param, value of params => url .= replace "/_#{param}/", "/#{value}/"
  req-json method, url, options, body

setup = (desc) ->
  if typeof desc is \string
    return req-json \GET, desc .then setup

  routes = flatten-routes desc.routes

  endpoints = {}
  for name, spec of desc.endpoints
    set-at endpoints, name, get-handler spec, routes[name]

  console.log endpoints
  Promise.resolve endpoints

$.ajax-setup {
  xhr-fields: with-credentials: true
}

root = if window.location.host.match /eraseallkittens\.com/ or window.location.port is \5275
  'https://api.eraseallkittens.com'
else
  '//localhost:3000'

setup window.API_DESC || "#root/v1"
  .tap (endpoints) -> module.exports <<< endpoints
