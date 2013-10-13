require! mediator

self.send = (evt, data) ~>
  try
    post-message {evt, data}
  catch error
    console.log "Couldn't send #evt: #error"

self.onmessage = (msg) ->
  on-done = (response) ->
    send "RESPONSE-#{msg.data.id}", response

  mediator.trigger msg.data.evt, msg.data.data, on-done

mediator.on \send, (data) -> self.send data.evt, data.data

unless self.console?
  self.console = {}
  self.console.log = ->
    send \WORKER_LOG, _.clone arguments

mediator.once \initWorker, (name) ->
  require name
