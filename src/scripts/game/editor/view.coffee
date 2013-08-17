mediator = require "game/mediator"

niceComments = require "game/editor/nice-comments"
setupCMExtras = require "game/editor/cm-extras"

module.exports = class EditorView extends Backbone.View
  initialize: (options) ->
    html = @model.get "html"

    @renderEl = options.renderEl if options.renderEl isnt undefined

    @entities = @renderEl.children ".entity"
    @entities.detach()

    cm = CodeMirror (@$ ".editor-html")[0],
      value: html
      mode: "htmlmixed"
      theme: "jsbin"
      tabsize: 2
      lineWrapping: true
      lineNumbers: true

    cm.on "change", @handleChange

    @cm = cm

    @hasErrors = false

    @listenTo @model, "change:html", @onChange

    @extras = setupCMExtras cm
    niceComments cm

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

    parsed = @extras.process html

    @hasErrors = parsed.error isnt null

    e.empty()
    e.append parsed.document

    @entities.clone().prependTo e

  restoreEntities: =>
    (@renderEl.children ".entity").remove()
    @entities.prependTo @renderEl

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
