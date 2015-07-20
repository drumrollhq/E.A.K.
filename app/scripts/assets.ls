require! {
  'audio/context'
}

audio-format = context.format

asset-cache = {}

export _cache = asset-cache

export function load-asset name
  if asset-cache[name]
    console.log "load-asset: cache HIT: \t#{name}"
    return asset-cache[name]

  console.log "load-asset: cache MISS:\t#{name}"
  throw new Error "Cache miss #name"

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
  if typeof file is \string then return file
  switch file.type
  | \json => file.data
  | \arraybuffer => base64-to-arraybuffer file.data
  | \image => base64-to-image file.format, file.data
  | otherwise => throw new TypeError "Unknown file encoding type #{file.type}"

function base64-to-arraybuffer data
  base64js.to-byte-array data .buffer

function base64-to-image format, data
  arr = base64js.to-byte-array data
  blob = new Blob [arr], type: "image/#{format}"
  URL.create-object-URL blob

# jQuery tweaks so we can load arraybuffers.
# From http://www.artandlogic.com/blog/2013/11/jquery-ajax-blobs-and-array-buffers/
$.ajax-transport '+*' (options, original-options, jq-xhr) ->
  if options.data-type in <[blob arraybuffer]>
    return {
      send: (headers, complete-callback) ->
        xhr = new XMLHttpRequest!
        url = options.url or window.location.href
        type = options.type or \GET
        data-type = options.data-type or 'text'
        data = options.data or null
        async = options.async or true

        if data-type not in <[blob arraybuffer]>
          throw new Error 'options.data-type isnt blob or arraybuffer.'

        xhr.add-event-listener 'load', ->
          res = {}
          res[data-type] = xhr.response
          complete-callback xhr.status, xhr.status-text, res, xhr.get-all-response-headers!

        xhr.open type, url, async
        xhr.response-type = data-type
        xhr.send data

      abort: -> jq-xhr.abort!
    }
