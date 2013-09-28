mediator = require "mediator"

self.send = (evt, data) =>
  try
    postMessage evt: evt, data: data
  catch e
    console.log "Couldn't send #{evt}"


self.onmessage = (msg) ->
  onDone = (response) ->
    send "RESPONSE-#{msg.data.id}", response
  mediator.trigger msg.data.evt, msg.data.data, onDone

mediator.on "send", (data) -> self.send data.evt, data.data

if self.console is undefined
  self.console = {}
  self.console.log = ->
    send "WORKER_LOG", _.clone arguments

mediator.once "initWorker", (name) ->
  require name
