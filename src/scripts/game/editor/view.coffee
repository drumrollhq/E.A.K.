module.exports = class EditorView extends Backbone.View
  initialize: ->
    html = @model.get "html"

    htmlData = @preProcessHTML html

    window.html = @preProcessHTML

    cm = CodeMirror (@$ ".editor-html")[0],
      value: htmlData.html
      mode: "htmlmixed"
      theme: "jsbin"
      tabsize: 2
      lineWrapping: true
      lineNumbers: true

    cm.on "change", @handleChange

    @addWidgets cm, htmlData.comments

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

  addWidgets: (cm, widgets) =>
    for widget in widgets
      n = document.createElement "div"
      n.className = "comment-widget"
      n.innerHTML = widget.html
      cm.addLineWidget widget.start.line, n,
        coverGutter: true
        noHScroll: true

      cm.markText widget.start, widget.end,
        readOnly: true
        collapsed: true

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

  preProcessHTML: (stream) ->
    if stream.length <= 1
      return html: stream, comments: []

    stream = html_beautify stream,
      indent_size: 2
      indent_char: ' '
      preserve_newlines: false

    htmlout = ""

    i = 0
    current = ''
    next = ''

    position =
      line: 0
      ch: -1

    pos = -> _.clone position

    consume = (app=true) ->
      if htmlout[htmlout.length - 1] is "\n"
        position.line++
        position.ch = 0
      else
        position.ch++

      current = stream[i]
      i++
      next = stream[i]

      if app then htmlout += current

      next

    comments = []

    while consume() isnt undefined
      if current is "<" and next is "!"
        commentStart = pos()
        consume()
        consume()
        if current is "-" and next is "-"
          # comment start
          currentComment = ""
          consume()
          while (if next is "\n" then consume false else consume true) isnt undefined
            if current is "-" and next is "-"
              consume()
              if next is ">"
                # comment end
                consume()
                consume()

                comments.push
                  html: currentComment
                  start: commentStart
                  end: pos()

                break
              else
                currentComment += "--"
            else
              currentComment += current

    console.log htmlout, comments

    return html: htmlout, comments: comments
