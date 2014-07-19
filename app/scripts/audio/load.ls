require! 'audio/context'

cache = {}

formats = <[mp3 ogg]> .filter (format) -> Modernizr.audio[format] is 'probably'
if empty formats then return module.exports = {}

format = first formats

module.exports = function fetch-audio-data url, cb
  if cache[url]? then return cb cache[url], null

  $.ajax {
    type: \GET
    url: "#{url}.#{format}"
    data-type: 'arraybuffer'
    error: (xhr, status, err) -> cb null, "Error loading #url: #status - #err"
    success: (data) ->
      success = (audio) ->
        cache[url] = audio
        cb audio, null

      err = (err) ->
        cb null, err

      context.decode-audio-data data, success, err
  }

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
