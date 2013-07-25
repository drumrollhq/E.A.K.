module.exports = class Editor extends Backbone.Model
  initialize: ->
    @set "originalhtml", @get "html"