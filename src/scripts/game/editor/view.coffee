module.exports = class EditorView extends Backbone.View
  initialize: ->
    cm = CodeMirror (@$ ".editor-html")[0],
      value: @model.get "html"
      mode: "htmlmixed"
      theme: "jsbin"
      tabsize: 2
      lineWrapping: true
      lineNumbers: true

    cm.on "change", @handleChange

    @cm = cm
    @doc = cm.getDoc()

    @listenTo @model, "change:html", @onChange

  events:
    "tap .save": "save"
    "tap .cancel": "cancel"
    "tap .undo": "undo"
    "tap .redo": "redo"

  handleChange: (cm) =>
    @model.set "html", cm.getValue()

  render: ->
    ($ document.body).addClass "editor"

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

    @renderEl.html html

    entities.appendTo e

  cancel: =>
    @model.set "html", @model.get "originalhtml"
    @model.trigger "save"

  save: =>
    @model.trigger "save"

  undo: =>
    console.log "called"
    @doc.undo()

  redo: =>
    @doc.redo()
