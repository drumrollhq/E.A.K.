# Hide comments from the source, replace them with line widgets that
# are clearly not code, beautifying the code in the process.
module.exports = NiceComments = (cm) ->

  html = cm.getValue()

  htmlData = preProcessHTML html

  cm.setValue htmlData.html

  addWidgets cm, htmlData.comments

# Beautify HTML and extract comments.
preProcessHTML = (stream) ->
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

# Add an array of widgets (objects with start, end, and html) properties to a codemirror instance.
addWidgets = (cm, widgets) ->
  for widget in widgets
    n = document.createElement "div"
    n.className = "annotation-widget"
    n.innerHTML = widget.html
    cm.addLineWidget widget.start.line, n,
      coverGutter: true
      noHScroll: true

    cm.markText widget.start, widget.end,
      readOnly: true
      collapsed: true
