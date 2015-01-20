require! 'audio/context'

cache = {}

module.exports = function fetch-audio-data url
  if cache[url]? then return cb cache[url], null

  Promise
    .resolve $.ajax {
      type: \GET
      url: "#{url}.#{context.format}?_v=#{EAKVERSION}"
      data-type: \arraybuffer
    }
    .then context.decode-audio-data-async
    .tap (audio) -> cache[url] = audio

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
