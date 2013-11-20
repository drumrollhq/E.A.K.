# WebWorker provides a layer of abstraction over Worker, the native way of using
# web workers. It provides the following features:
#
# * Start a particular worker by requiring a commonjs module, as defined by the
#   name property
# * Uses Backbone's event system for listening to messages from the worker
# * Each message sent to the worker has a unique ID, and can have callbacks
#   attached to it. The callbacks should be triggered when the worker has
#   finished processing the instruction.
# * If the browser doesn't support console.log for Workers, we try to provide a
#   polyfill for it

# All instances of WebWorker share one message-id counter
message-id = 0

# get-message-id takes an event name and returns a unique ID. We could just use
# the message-id counter, but including the event name is helpful when debugging
# and the random string makes us less likely to clash with user-defined names.
get-message-id = (evt) ->
  message-id++
  "##{message-id}-#evt-#{Math.random!.to-string 36 .substr 2}"

# Syntax for creating a new worker (assuming js/worker.js contains something
# compatible with this protocol, and has a commonjs module named 'sample'):
#
# worker = new WebWorker({name: 'sample'});
#
module.exports = class WebWorker extends Backbone.Model
  defaults: name: ""

  initialize: ~>
    console.log "CREATE WORKER: #{@get 'name'}"

    # Creata a native WebWorker
    @worker = new Worker "/js/worker.js"

    # When we get a message from the worker, trigger an event with the name and
    # data the should have been sent with it
    @worker.onmessage = (msg) ~> @trigger msg.data.evt, msg.data.data

    # Faux console.log for workers
    @on \WORKER_LOG (data) -> _.to-array data |> console.log.apply console, _

    # Send the message that should start up the relevant commonjs module
    @send "initWorker" @get "name"

  # Send an event / instruction to the worker.
  send: (evt, data, callback = false) ~>
    # Fetch a unique ID for the message
    id = get-message-id evt

    # Try to send the message. This is likely to fail if the data is circular /
    # contains functions etc.
    try
      @worker.post-message {evt, data, id}
    catch error
      console.log error, evt, data
      return

    # If we've been given a callback function, listen for a response. The worker
    # function should send a response when the message has been dealt with
    if typeof callback is 'function'
      data <- @once "RESPONSE-#id"
      callback data

  # Fairly self explanatory.
  kill: ~> @worker.terminate!
