require "events"

mediator = {}

_.extend mediator, Events

mediator.send = (evt, data) ->
  mediator.trigger "send", evt: evt, data: data

module.exports = mediator