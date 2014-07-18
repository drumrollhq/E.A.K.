require! {
  'channels'
  'audio/context'
}

formats = <[mp3 ogg wav]> .filter (format) -> Modernizr.audio[format] is 'probably'
if empty formats then return module.exports = {}

format = first formats

module.exports = class Sound
  (@_path, @_track) ->

  load: (cb) ~>
    buffer, err <~ fetch-audio-data @_path
    if err then return cb err
    @_buffer = buffer
    cb!

  start: ~>
    sound-source = context.create-buffer-source!
    sound-source.buffer = @_buffer
    sound-source.connect @_track.node
    sound-source.onended = ~> sound-source.disconnect @_track.node
    sound-source.start 0, 0, @_buffer.duration
    sound-source

function fetch-audio-data url, cb
  $.ajax {
    type: \GET
    url: "#{url}.#{format}"
    data-type: 'arraybuffer'
    error: (xhr, status, err) -> cb null, "Error loading #url: #status - #err"
    success: (data) ->
      success = (audio) -> cb audio, null
      err = (err) -> cb err
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
