require "events"

mediator = {}

_.extend mediator, Events

mediator.send = (evt, data) ->
  mediator.trigger "send", evt: evt, data: data

setInterval ->
  mediator.trigger "frame"
, 1000 / 60

module.exports = mediator