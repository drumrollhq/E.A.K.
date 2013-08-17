###

Extra bits that make CM a better editor to learn with:
- When editing an element in CM, it is shown and highlighted in the preview
- If you click and element in the preview, the corresponding text is selected in the editor.

###

module.exports = setupCMExtras = (cm) ->
  lastMark = false

  marks = []

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

        showElement mark.data.node

        lastMark = mark

  return change: (html) ->
    parsed = Slowparse.HTML document, html

    clearMarks()
    linkToPreview parsed.document, marks, cm

    return parsed

clearMarks: (marks) ->
  if marks isnt undefined
    until mark = marks.shift() is undefined
      mark.clear()

showElement = (el) ->
  el.scrollIntoView(true)

linkToPreview = (node, marks, cm) =>
  if node.parseInfo isnt undefined and node.nodeType is 1

    pos = getPositions node.parseInfo, cm

    mark = cm.markText pos.start.outer, pos.start.inner

    mark.data = node: node
    marks.push mark

    node.addEventListener "click", (e) =>
      e.stopPropagation()

      cm.setSelection pos.start.inner, pos.end.inner
      cm.focus()

    , false

  for n in node.childNodes
    linkToPreview n, marks, cm

getPositions = (info, cm) ->
  pos =
    start: {}
    end: {}
  if info.openTag isnt undefined
    pos.start.outer = cm.posFromIndex info.openTag.start
    pos.start.inner = cm.posFromIndex info.openTag.end
  else
    pos.start.inner = pos.start.outer = cm.posFromIndex info.start

  if info.closeTag isnt undefined
    pos.end.outer = cm.posFromIndex info.closeTag.end
    pos.end.inner = cm.posFromIndex info.closeTag.start
  else
    pos.end.inner = end.outer = cm.posFromIndex info.end

  return pos
