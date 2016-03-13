init = ->
  unless window.performance and window.performance.now
    do
      start-time = Date.now!
      window.performance = {
        now: -> Date.now! - start-time
      }

  require 'plugins'
  Init = require 'Init'
  window.eak = (new Init el: $ \#main).app

window.async-array-to-string = async-array-to-string = (array) -> new Promise (resolve) ->
  f = new FileReader!
  f.onload = (e) -> resolve e.target.result
  f.read-as-text new Blob [array]

array-to-string = (array) ->
  out = ''
  len = array.length
  i = 0

  while i < len
    c = array[i++]
    out += switch c .>>. 4
      case 0, 1, 2, 3, 4, 5, 6, 7 =>
        String.from-char-code c
      case 12, 13 =>
        String.from-char-code (((c .&. 0x1F) .<<. 6) .|. (array[i++] .&. 0x3F))
      case 14 =>
        String.from-char-code (((c .&. 0x0F) .<<. 12) .|. ((array[i++] .&. 0x3F) .<<. 6) .|. ((array[i++] .&. 0x3F) .<<. 0))

  out

window.parse-eak-package = parse-eak-package = (buffer) ->
  const HEADERS_END = '\0'.char-code-at 0
  const HEADERS_SEP = '|'.char-code-at 0
  const HEADER_FIELD_SEP = ';'.char-code-at 0
  headers = []
  header = []
  files = {}
  start = 0

  for c, i in buffer
    switch c
      case HEADERS_END
        start += 1
        for [name, type, size] in headers
          files[name] = { type, content: buffer.subarray start, start += size }
        return files
      case HEADERS_SEP
        [name, type, size] = header
        header = []
        headers.push [name, type, parse-int size, 10]
        start += 1
      case HEADER_FIELD_SEP
        header.push array-to-string buffer.subarray start, i
        start = i + 1

  files

if window.EAK_OPTIMIZED
  <- document.add-event-listener \DOMContentLoaded, _, false

  failed = false
  dialogue = document.query-selector '.loader'
  bar = dialogue.query-selector '.bar'
  progress = dialogue.query-selector '.progress'
  bar-inner = bar.children.0

  on-load = (e) ->
    finished parse-eak-package new Uint8Array e.target.response

  on-error = ->
    if not failed
      failed := true
      alert 'Oh no! we couldn\'t load all the assets for Erase All Kittens! :('

  on-progress = (progress) ->
    update-progress progress.loaded

  update-progress = (loaded) ->
    percent = "#{Math.round (loaded / window.EAK_PACKAGE_SIZE) * 100}%"
    progress.text-content = bar-inner.style.width = percent

  finished = (data) ->
    last-decoder = Promise.resolve!
    for let name, {content} of data
      last-decoder := last-decoder.then -> async-array-to-string content .then (str) ->
        if name.match /\.js$/
          el = document.create-element \script
          el.text-content = str
          document.body.append-child el
        else if name.match /\.css$/
          el = document.create-element \style
          el.type = 'text/css'
          el.append-child document.create-text-node str
          document.head.append-child el

    last-decoder.then ->
      bar.style.display = progress.style.display = 'none'
      init!

  req = new XML-http-request!
  req.add-event-listener \load, on-load, false
  req.add-event-listener \error, on-error, false
  req.add-event-listener \abort, on-error, false
  req.add-event-listener \progress, on-progress, false
  req.open \GET, "#{window.EAK_PACKAGE_SRC}?_v=#{window.EAKVERSION}"
  req.response-type = \arraybuffer
  req.send!
else
  $ -> init!
