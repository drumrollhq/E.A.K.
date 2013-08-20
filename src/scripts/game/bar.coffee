mediator = require "game/mediator"

module.exports = class Bar extends Backbone.View
  events:
    "tap .edit": "edit"
    "tap .restart": "restart"

  edit: (e) =>
    e.preventDefault()
    e.stopPropagation()
    mediator.trigger "edit"

  restart: (e) =>
    e.preventDefault()
    e.stopPropagation()
    mediator.trigger "restart"
