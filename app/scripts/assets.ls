require! {
  'audio/context'
}

audio-format = context.format

asset-cache = {}

export _cache = asset-cache

export function load-asset name, type
  unless asset-cache[name]
    throw new Error "load-asset: cache MISS #name"

  console.log "load-asset: cache HIT: #{name}"
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
    .then (bundle) ->
      for name, file of bundle
        asset-cache[name] = debundle file

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
