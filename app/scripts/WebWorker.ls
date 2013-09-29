message-id = 0

get-message-id = (evt) ->
  message-id++
  "##{message-id}-#evt-#{Math.random!.to-string 36 .substr 2}"

module.exports = class WebWorker extends Backbone.Model
  defaults: name: ""

  initialize: ~>
    console.log "CREATE WORKER: #{@get 'name'}"
    @worker = new Worker "js/worker.js"

    @worker.onmessage = (msg) ~> @trigger msg.data.evt, msg.data.data

    @on \WORKER_LOG (data) -> _.to-array data |> console.log.apply console, _

    @send "initWorker" @get "name"

  send: (evt, data, callback = false) ~>
    id = get-message-id evt
    try
      @worker.post-message {evt, data, id}
    catch error
      console.log error, evt, data
      return

    data <- @once "RESPONSE-#id"

    if typeof callback is \function then callback data

  kill: ~> @worker.terminate!
