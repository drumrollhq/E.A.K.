mediator = require "game/mediator"

module.exports = class Bar extends Backbone.View
  events:
    "click .edit": "edit"
    "click .restart": "restart"

  edit: (e) =>
    e.preventDefault()
    e.stopPropagation()
    mediator.trigger "edit"

  restart: (e) =>
    e.preventDefault()
    e.stopPropagation()
    mediator.trigger "restart"
