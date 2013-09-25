mediator = require "mediator"

self.send = (evt, data) =>
  try
    postMessage evt: evt, data: data
  catch e
    console.log "Couldn't send #{evt}"


self.onmessage = (msg) ->
  mediator.trigger msg.data.evt, msg.data.data

mediator.on "send", (data) -> self.send data.evt, data.data

if self.console is undefined
  self.console = {}
  self.console.log = ->
    send "WORKER_LOG", _.clone arguments

mediator.once "initWorker", (name) ->
  console.log "I've initWorker'd!"
  require name
