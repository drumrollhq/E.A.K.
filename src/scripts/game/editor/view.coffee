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
      cm.addLineWidget widget.line-1, n,
        coverGutter: true
        noHScroll: true

      cm.markText {line: widget.line-2, ch: Infinity}, {line: widget.line, ch: 0},
        readOnly: true

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

    stream = "\n"+stream

    i = 0
    current = ''
    next = ''

    line = 0

    consume = ->
      current = stream[i]
      i++
      next = stream[i]

      next

    htmlout = ""
    comments = []

    while consume() isnt undefined
      if current is "<" and next is "!"
        consume()
        consume()
        if current is "-" and next is "-"
          # comment start
          currentComment = ""
          consume()
          while consume() isnt undefined
            if current is "-" and next is "-"
              consume()
              if next is ">"
                # comment end
                comments.push
                  html: currentComment
                  line: line

                consume()

                # Get rid of any trailing whitespace after the comment:
                while next in [" ", "\t", "\n", "\r"]
                  consume()

                break
              else
                currentComment += "--"
            else
              currentComment += current

        else
          htmlout += "<!-"
      else
        if current is "\n" then line++
        htmlout += current

    console.log htmlout, comments

    return html: htmlout, comments: comments

  blockEls: ["address", "article", "aside", "audio", "blockquote", "canvas",
    "dd", "div", "dl", "fieldset", "figcaption", "figure", "footer", "form",
    "h1", "h2", "h3", "h4", "h5", "h6", "header", "hgroup", "hr", "noscript",
    "ol", "output", "p", "pre", "section", "table", "tfoot", "ul", "video"]
