mediator = require "game/mediator"

boxShadow = Modernizr.prefixed "boxShadow"

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

    @hasErrors = false

    @listenTo @model, "change:html", @onChange

    @setupCMExtras @cm

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

    parsed = Slowparse.HTML document, html

    @hasErrors = parsed.error isnt null


    @clearEditorExtras()
    @editorFocusing parsed.document

    e.empty()
    e.append parsed.document

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

  editorFocusing: (node) =>
    if node.parseInfo isnt undefined and node.nodeType is 1

      info = node.parseInfo

      if info.openTag isnt undefined
        startOuter = @cm.posFromIndex info.openTag.start
        startInner = @cm.posFromIndex info.openTag.end
      else
        startInner = startOuter = @cm.posFromIndex info.start

      if info.closeTag isnt undefined
        endOuter = @cm.posFromIndex info.closeTag.end
        endInner = @cm.posFromIndex info.closeTag.start
      else
        endInner = endOuter = @cm.posFromIndex info.end

      mark = @cm.markText startOuter, endOuter

      mark.data = node: node
      @editormarks.push mark

      node.addEventListener "click", (e) =>
        e.stopPropagation()

        @cm.setSelection startInner, endInner
        @cm.focus()

      , false

    for n in node.childNodes
      @editorFocusing n

  clearEditorExtras: (fully=false) =>
    if @editormarks isnt undefined
      for mark in @editormarks
        mark.clear()

    @editormarks = []

  setupCMExtras: (cm) =>
    lastMark = false
    cm.on "cursorActivity", =>
      if lastMark isnt false
        lastMark.data.node.style[boxShadow] = lastMark.data.shadow

      pos = cm.getCursor()
      marks = cm.findMarksAt pos
      if marks.length isnt 0
        mark = marks[marks.length - 1]

        if mark.data isnt undefined
          mark.data.shadow = mark.data.node.style[boxShadow]
          if mark.data.shadow is ""
            mark.data.node.style[boxShadow] = "0 0 10px rgba(30, 200, 255, 0.8)"
          else
            mark.data.node.style[boxShadow] += ", 0 0 10px rgba(30, 200, 255, 0.8)"

          @showElement mark.data.node

          lastMark = mark

  showElement: (el) =>
    el.scrollIntoView(true)

  cancel: =>
    @model.set "html", @model.get "originalhtml"
    @model.trigger "save"

  save: =>
    if @hasErrors
      mediator.trigger "alert", "There are errors in your code! Fix them before saving."
      return

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

    return html: htmlout, comments: comments
