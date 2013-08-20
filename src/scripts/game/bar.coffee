mediator = require "game/mediator"

module.exports = class Bar extends Backbone.View
  events:
    "tap .edit": "edit"
    "tap .restart": "restart"

  initialize: ->
    mediator.on "keypress:e", ->
      mediator.trigger "edit"

  edit: (e) ->
    e.preventDefault()
    e.stopPropagation()
    mediator.trigger "edit"
    e.target.blur()

  restart: (e) ->
    e.preventDefault()
    e.stopPropagation()
    mediator.trigger "restart"
    e.target.blur()
