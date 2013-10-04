module.exports = class Editor extends Backbone.Model
  initialize: ->
    @set "startHTML", @get "html"
    @set "startCSS", @get "css"
