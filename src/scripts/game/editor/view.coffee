mediator = require "game/mediator"

niceComments = require "game/editor/nice-comments"
setupCMExtras = require "game/editor/cm-extras"

boxShadow = Modernizr.prefixed "boxShadow"

module.exports = class EditorView extends Backbone.View
  initialize: ->
    html = @model.get "html"

    cm = CodeMirror (@$ ".editor-html")[0],
      value: html
      mode: "htmlmixed"
      theme: "jsbin"
      tabsize: 2
      lineWrapping: true
      lineNumbers: true

    niceComments cm

    cm.on "change", @handleChange

    @cm = cm
    @doc = cm.getDoc()

    @hasErrors = false

    @listenTo @model, "change:html", @onChange

    @extras = setupCMExtras cm

  events:
    "tap .save": "save"
    "tap .cancel": "cancel"
    "tap .undo": "undo"
    "tap .redo": "redo"

  handleChange: (cm) =>
    @model.set "html", cm.getValue()

  render: ->
    ($ document.body).addClass "editor"

    # force change:
    @onChange @model, @cm.getValue()

  remove: =>
    ($ document.body).removeClass "editor"
    @stopListening()
    @cm.off "change", @handleChange
    ($ @cm.getWrapperElement()).remove()

  onChange: (m, html) =>
    # preserve all entities:
    e = @renderEl

    entities = e.children ".entity"
    entities.detach()

    parsed = @extras.process html

    @hasErrors = parsed.error isnt null

    e.empty()
    e.append parsed.document

    entities.appendTo e

  cancel: =>
    @model.set "html", @model.get "originalhtml"
    @model.trigger "save"

  save: =>
    if @hasErrors
      mediator.trigger "alert", "There are errors in your code! Fix them before saving."
      return

    @model.trigger "save"

  undo: =>
    @cm.undo()

  redo: =>
    @cm.redo()
