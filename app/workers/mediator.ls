require! events

mediator = {}

_.extend mediator, Events

mediator.send = (evt, data) ->
  mediator.trigger "send", {evt, data}

module.exports = mediator
