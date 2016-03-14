require! {
  'audio/context'
  'lib/lang/CSS'
}

audio-format = context.format

asset-cache = {}
loaded-bundles = {}
registered-actors = {}
registered-modules = {}
registered-area-scripts = {}
registered-level-scripts = {}
added-css = {}

bundle-sizes = {}

Promise.resolve $.get-JSON "/bundles.#{EAKVERSION}.json"
  .then (sizes) -> bundle-sizes := sizes

export _cache = {assets: asset-cache, loaded-bundles, registered-actors, added-css}

export function load-asset name, type, mime-hint
  name .= replace /^\//, ''
  unless asset-cache[name]
    if type is \url
      console.log "[assets] load-asset: cache MISS #name"
      return "#{name}?_v=#{EAKVERSION}"

    throw new Error "[assets] load-asset: cache MISS #name"

  cached = asset-cache[name]
  if type?
    if cached[type]?
      return cached[type]
    else if type is \url and cached.string
      return cached.url = string-to-url cached.string, mime-hint
    else if type is \url and cached.json
      return cached.url = string-to-url (JSON.stringify cached.json), 'application/json'
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
    filename = "#{bundle-name}/bundled.#{audio-format}.#{EAKVERSION}.eakpackage"
    on-load = (e) ->
      progress null
      resolve parse-eak-package new Uint8Array e.target.response

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
    xhr.response-type = \arraybuffer
    xhr.open \GET "#{filename}?_v=#{EAKVERSION}"
    xhr.send!

  req
    .tap (bundle) ->
      loaded-bundles[bundle-name] = []
      debundlers = for let name, file of bundle
        debundle file .then (file) ->
          loaded-bundles[bundle-name][*] = name
          asset-cache[name] = file
      Promise.all debundlers

    .tap (bundle) ->
      for name, {type} of bundle
        if type is 'application/javascript' then add-js asset-cache[name].default, bundle-name, name
        if type is 'text/css' then add-css asset-cache[name].default, bundle-name, name

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

  if registered-area-scripts[bundle-name]
    for script in registered-area-scripts[bundle-name]
      script.deregister!
    delete registered-area-scripts[bundle-name]

  if registered-level-scripts[bundle-name]
    for script in registered-level-scripts => script.deregister!
    delete registered-level-scripts[bundle-name]

  if registered-modules[bundle-name]
    for module in registered-modules[bundle-name]
      window.require.de-register module
      console.log "[assets] de-registered module #name"
    delete registered-modules[bundle-name]

  if added-css[bundle-name]
    for el in added-css[bundle-name]
      document.head.remove-child el
      console.log "[assets] removed stylesheet #{el.name}"
    delete added-css[bundle-name]

  delete loaded-bundles[bundle-name]

decode = ({type, content}) ->
  switch type
    case \application/json
      async-array-to-string content .then (str) ->
        default: \json, string: str, json: JSON.parse str
    case \application/javascript, \text/css, \text/html, \text/vtt
      async-array-to-string content .then (str) ->
        default: \string, string: str
    case \audio/mpeg, \audio/ogg
      blob = new Blob [content], {type}
      url = URL.create-object-URL blob
      tag = document.create-element \audio
      tag.src = url
      default: \url, url: url, audio: tag
    case \image/png, \image/jpeg, \image/gif
      blob = new Blob [content], {type}
      url = URL.create-object-URL blob
      tag = document.create-element \img
      tag.src = url
      default: \url, url: url, image: tag
    default
      throw new TypeError "Unknown file type #type"

export function debundle file
  Promise.resolve decode file .then (decoded-file) ->
    decoded-file.byte-array = file.content
    decoded-file.buffer = file.content.buffer
    decoded-file.default = decoded-file[decoded-file.default]
    decoded-file

# export function debundle {type, content}
#   switch type
#     case \string
#       default: file.data, string: file.data
#     case \application/json
#       async-array-to-string content .then str ->
#         default: file.data, json: (JSON.parse str), buffer:
#     case \audio/mpeg, \audio/ogg
#       blob = new Blob [content], file.{type}
#       url = URL.create-object-URL blob
#       tag = document.create-element \audio
#       tag.src = url
#       default: url, url: url, buffer: content, audio: tag
#     case \image
#       data = base64js.to-byte-array file.data
#       blob = new Blob [data], type: "image/#{file.format}"
#       url = URL.create-object-URL blob
#       tag = document.create-element \img
#       tag.src = url
#       default: url, url: url, buffer: data.buffer, image: tag
#     default
#       throw new TypeError "Unknown file type #{file.type}"

text-encoder = new TextEncoderLite \utf-8
function string-to-url str, mime
  data = text-encoder.encode str
  blob = new Blob [data], type: mime
  URL.create-object-URL blob

function add-js js, bundle-name, name
  registered-actors[bundle-name] ?= []
  registered-area-scripts[bundle-name] ?= []
  registered-level-scripts[bundle-name] ?= []
  registered-modules[bundle-name] ?= []

  # intercept eak register functions
  eak = window.eak
  original-eak = eak.{register-actor, register-area-script, register-level-script}
  eak.register-actor = (ctor) ->
    registered-actors[bundle-name][*] = dasherize ctor.display-name
    original-eak.register-actor.apply this, arguments

  eak.register-area-script = (name, obj) ->
    registered-area-scripts[bundle-name][*] = original-eak.register-area-script.apply this, arguments

  eak.register-level-script = (name, obj) ->
    registered-level-scripts[bundle-name][*] = original-eak.register-level-script.apply this, arguments

  # intercept require.register
  require = window.require.local name
  require <<< window.require
  require.register = (module-name) ->
    registered-modules[bundle-name][*] = module-name
    console.log "[assets] Registered module #module-name from #name"
    window.require.register.apply this, arguments

  fn = new Function 'eak', 'require', "#{js}\n\n//# sourceURL=#name"
  fn eak, require

  # restore eak functions
  window.eak <<< original-eak

function add-css source, bundle-name, name
  added-css[bundle-name] ?= []
  css = new CSS source
    ..rewrite-assets (url) ->
      if url.match /^(\/\/|https?:|blob:)/ then url else load-asset url, \url

  source = css.to-string!
  el = document.create-element \style
    ..type = 'text/css'
    ..append-child document.create-text-node css.to-string!
    ..name = name
  document.head.append-child el
  console.log "[assets] Add stylesheet #name"
  added-css[bundle-name][*] = el
