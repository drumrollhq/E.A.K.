# Hide comments from the source, replace them with line widgets that
# are clearly not code, beautifying the code in the process.
module.exports = NiceComments = (cm) ->
  html = cm.get-value!
  html-data = pre-process-HTML html
  cm.set-value html-data.html
  add-widgets cm, html-data.comments

# Beautify HTML and extract comments.
pre-process-HTML = (stream) ->
  if stream.length <= 1
    return html: stream, comments: []

  stream = html_beautify stream, {
    indent_size: 2
    indent_char: ' '
    preserve_newlines: false
  }

  htmlout = ''

  i = 0
  current = ''
  next = ''

  position = line: 0, ch: -1

  pos = -> _.clone position

  consume = (app = true) ->
    if htmlout[htmlout.length - 1] is "\n"
      position.line++
      position.ch = 0
    else
      position.ch++

    current := stream[i]
    i++
    next := stream[i]

    if app then htmlout += current

    next

  comments = []

  while consume! isnt undefined
    if current is '<' and next is '!'
      comment-start = pos!
      consume!
      consume!
      if current is '-' and next is '-'
        # comment start
        current-comment = ''
        consume!
        while (if next is '\n' then consume false else consume true) isnt undefined
          if current is '-' and next is '-'
            consume!
            if next is '>'
              # comment end
              consume!
              consume!

              comments[*] = {
                html: current-comment
                start: comment-start
                end: pos!
              }

              break
            else
              current-comment += '--'
          else
            current-comment += current

  return {html: htmlout, comments: comments}

# Add an array of widgets (objects with start, end, and html) properties to a codemirror instance.
add-widgets = (cm, widgets) ->
  for widget in widgets
    n = document.create-element \div
    n.class-name = \annotation-widget
    n.inner-HTML = widget.html
    cm.add-line-widget widget.start.line, n, {+cover-gutter, +no-h-scroll}
    cm.markText widget.start, widget.end, {+read-only, +collapsed}
