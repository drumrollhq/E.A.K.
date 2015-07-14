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

if window.EAK_OPTIMIZED
  <- document.add-event-listener \DOMContentLoaded, _, false

  failed = false
  dialogue = document.query-selector '.loader'
  bar = dialogue.query-selector '.bar'
  progress = dialogue.query-selector '.progress'
  bar-inner = bar.children.0

  on-load = (e) ->
    finished JSON.parse e.target.response

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
    for own name, content of data
      if name.match /\.js$/
        el = document.create-element \script
        el.text-content = content
        document.body.append-child el
      else if name.match /\.css$/
        el = document.create-element \style
        el.type = 'text/css'
        el.append-child document.create-text-node content
        document.head.append-child el

    bar.style.display = progress.style.display = 'none'
    init!

  req = new XML-http-request!
  req.add-event-listener \load, on-load, false
  req.add-event-listener \error, on-error, false
  req.add-event-listener \abort, on-error, false
  req.add-event-listener \progress, on-progress, false
  req.open \GET, window.EAK_PACKAGE_SRC
  req.send!
else
  $ -> init!
