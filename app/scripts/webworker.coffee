messageId = 0

getMessageId = (evt) ->
  messageId++
  return "##{messageId}-#{evt}-#{Math.random().toString(36).substr(2)}"

module.exports = class WebWorker extends Backbone.Model
  defaults:
    name: ""

  initialize: =>
    console.log "CREATE WORKER:", @get "name"
    @worker = new Worker "js/worker.js"
    @worker.onmessage = (msg) => @trigger msg.data.evt, msg.data.data

    @on "WORKER_LOG", (data) ->
      out = []
      out.push data[d] for d of data
      console.log.apply console, out

    @send "initWorker", @get "name"

  send: (evt, data, callback = no) =>
    id = getMessageId evt
    try
      @worker.postMessage evt: evt, data: data, id: id
    catch e
      console.log e, evt, data
      return

    @once "RESPONSE-#{id}", (data) ->
      if typeof callback is "function"
        callback data

  kill: => @worker.terminate()
