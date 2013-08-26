mediator = require "game/mediator"

module.exports = class AlertPointer extends Backbone.View
  initializdae: (hint) ->
    console.log hint
    @message = hint.content

  render: ->
    mediator.trigger "alert", @message
