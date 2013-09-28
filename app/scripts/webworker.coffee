module.exports = class WebWorker extends Backbone.Model
  defaults:
    name: ""

  initialize: =>
    @worker = new Worker "js/worker.js"
    @worker.onmessage = (msg) => @trigger msg.data.evt, msg.data.data

    @on "WORKER_LOG", (data) ->
      out = []
      out.push data[d] for d of data
      console.log.apply console, out

    @send "initWorker", @get "name"

  send: (evt, data) =>
    try
      @worker.postMessage evt: evt, data: data
    catch e
      console.log e, evt, data

  kill: => @worker.terminate()