module.exports = class WebWorker extends Backbone.Model
  defaults:
    name: ""

  initialize: =>
    @worker = new Worker "js/worker.js"
    @worker.onmessage = (msg) => @trigger msg.data.evt, msg.data.data

    @on "WORKER_LOG", (d) -> console.log d

    @send "initWorker", @get "name"

  send: (evt, data) =>
    @worker.postMessage evt: evt, data: data