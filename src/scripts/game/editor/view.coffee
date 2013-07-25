module.exports = class EditorView extends Backbone.View
  initialize: ->
    console.log @$ ".editor-html"
    cm = CodeMirror (@$ ".editor-html")[0],
      value: @model.get "html"
      mode: "htmlmixed"
      theme: "jsbin"
      tabsize: 2
      lineWrapping: true
      lineNumbers: true

    cm.on "change", (cm) =>
      @model.set "html", cm.getValue()

    @cm = cm
    @doc = cm.getDoc()

    @listenTo @model, "change:html", @onChange

  events:
    "tap .save": "save"
    "tap .cancel": "cancel"
    "tap .undo": "undo"
    "tap .redo": "redo"

  render: ->
    ($ document.body).addClass "editor"

  remove: ->
    ($ document.body).removeClass "editor"
    super

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
