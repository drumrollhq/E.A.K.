require! {
  'audio/context'
  'lib/lang/CSS'
}

audio-format = context.format

asset-cache = {}

export _cache = asset-cache

export function load-asset name, type
  unless asset-cache[name]
    if type is \url
      console.log "load-asset: cache MISS #name"
      return "#{name}?_v=#{EAKVERSION}"

    throw new Error "load-asset: cache MISS #name"

  cached = asset-cache[name]
  if type?
    if cached[type]?
      return cached[type]
    else throw new TypeError "Cannot load type #{type} for #{name}"
  else
    cached.default

export function load-assets names, data-type
  Promise.map names, (name) -> load-asset name, data-type

export function clear name
  delete asset-cache[name]

export function load-bundle name, progress
  if name.0 isnt '/' then name = "/#name"
  Promise.resolve ($.ajax "#{name}/bundled.#{audio-format}.json?_v=#{EAKVERSION}", data-type: \json .progress progress)
    .tap (bundle) ->
      for name, file of bundle
        asset-cache[name] = debundle file
    .tap (bundle) ->
      for name of bundle
        if name.match /\.js$/ then add-js asset-cache[name].default
        if name.match /\.css$/ then add-css asset-cache[name].default

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

function add-js js
  eval js

function add-css source
  css = new CSS source
    ..rewrite-assets (url) ->
      if url.match /^(\/\/|https?:|blob:)/ then url else load-asset url, \url

  source = css.to-string!
  el = document.create-element \style
    ..type = 'text/css'
    ..append-child document.create-text-node css.to-string!
  document.head.append-child el
