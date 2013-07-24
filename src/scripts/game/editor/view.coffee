module.exports = class EditorView extends Backbone.View
  tagName: "div"
  className: "editor-view"

  initialize: ->

  render: ->
    ($ document.body).addClass "editor"