mediator = require "game/mediator"

module.exports = class AlertPointer extends Backbone.View
  initialize: (hint) ->
    @message = hint.content

  render: ->
    mediator.trigger "alert", @message
