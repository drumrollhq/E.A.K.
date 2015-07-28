require! {
  'audio/context'
  'lib/lang/CSS'
}

audio-format = context.format

asset-cache = {}
loaded-bundles = {}
registered-actors = {}
registered-modules = {}
added-css = {}

bundle-sizes = {}

Promise.resolve $.get-JSON '/bundles.json'
  .then (sizes) -> bundle-sizes := sizes

export _cache = {assets: asset-cache, loaded-bundles, registered-actors, added-css}

export function load-asset name, type
  unless asset-cache[name]
    if type is \url
      console.log "[assets] load-asset: cache MISS #name"
      return "#{name}?_v=#{EAKVERSION}"

    throw new Error "[assets] load-asset: cache MISS #name"

  cached = asset-cache[name]
  if type?
    if cached[type]?
      return cached[type]
    else throw new TypeError "[assets] Cannot load type #{type} for #{name}"
  else
    cached.default

export function load-assets names, data-type
  Promise.map names, (name) -> load-asset name, data-type

export function clear name
  delete asset-cache[name]

export function load-bundle bundle-name, progress
  progress ?= -> null
  if bundle-name.0 isnt '/' then bundle-name = "/#bundle-name"
  req = new Promise (resolve, reject) ->
    filename = "#{bundle-name}/bundled.#{audio-format}.json"
    on-load = (e) ->
      progress null
      resolve JSON.parse e.target.response

    on-progress = (e) ->
      if bundle-sizes[filename]
        progress e.loaded / bundle-sizes[filename]
      else
        progress null

    xhr = new XML-http-request!
    xhr.add-event-listener \load, on-load, false
    xhr.add-event-listener \abort, reject, false
    xhr.add-event-listener \error, reject, false
    xhr.add-event-listener \progress, on-progress, false
    xhr.open \GET "#{filename}?_v=#{EAKVERSION}"
    xhr.send!

  req
    .tap (bundle) ->
      loaded-bundles[bundle-name] = []
      for name, file of bundle
        asset-cache[name] = debundle file
        loaded-bundles[bundle-name][*] = name

    .tap (bundle) ->
      for name of bundle
        if name.match /\.js$/ then add-js asset-cache[name].default, bundle-name
        if name.match /\.css$/ then add-css asset-cache[name].default, bundle-name

export function unload-bundle bundle-name
  for name in loaded-bundles[bundle-name]
    file = asset-cache[name]
    if file.url and file.url.match /^blob:/
      URL.revoke-object-URL file.url
    delete asset-cache[name]

  if registered-actors[bundle-name]
    for actor in registered-actors[bundle-name]
      window.eak.deregister-actor actor
    delete registered-actors[bundle-name]

  if registered-modules[bundle-name]
    for module in registered-modules[bundle-name]
      window.require.de-register module
      console.log "[assets] de-registered module #name"
    delete registered-modules[bundle-name]

  if added-css[bundle-name]
    for el in added-css[bundle-name]
      document.head.remove-child el
    delete added-css[bundle-name]

  delete loaded-bundles[bundle-name]

export function debundle file
  if typeof file is \string then file = data: file, type: \string
  switch file.type
    case \string
      default: file.data, string: file.data
    case \json
      default: file.data, json: file.data
    case \audio
      data = base64js.to-byte-array file.data
      blob = new Blob [data], type: "audio/#{file.format}"
      url = URL.create-object-URL blob
      tag = document.create-element \audio
      tag.src = url
      default: url, url: url, buffer: data.buffer, audio: tag
    case \image
      data = base64js.to-byte-array file.data
      blob = new Blob [data], type: "image/#{file.format}"
      url = URL.create-object-URL blob
      tag = document.create-element \img
      tag.src = url
      default: url, url: url, buffer: data.buffer, image: tag
    default
      throw new TypeError "Unknown file type #{file.type}"

function add-js js, bundle-name
  registered-actors[bundle-name] ?= []
  registered-modules[bundle-name] ?= []

  # intercept eak register functions
  eak = window.eak
  original-eak = eak.{register-actor}
  eak.register-actor = (ctor) ->
    registered-actors[bundle-name][*] = dasherize ctor.display-name
    original-eak.register-actor.apply this, arguments

  # intercept require.register
  original-register = window.require.register
  window.require.register = (name) ->
    registered-modules[bundle-name][*] = name
    console.log "[assets] Registered module #name"
    original-register.apply this, arguments

  fn = new Function 'eak', js
  fn eak

  # restore eak functions
  window.eak <<< original-eak
  # restore require.register
  window.require.register = original-register

function add-css source, bundle-name
  added-css[bundle-name] ?= []
  css = new CSS source
    ..rewrite-assets (url) ->
      if url.match /^(\/\/|https?:|blob:)/ then url else load-asset url, \url

  source = css.to-string!
  el = document.create-element \style
    ..type = 'text/css'
    ..append-child document.create-text-node css.to-string!
  document.head.append-child el
  added-css[bundle-name][*] = el
