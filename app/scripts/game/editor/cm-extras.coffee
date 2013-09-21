###

Extra bits that make CM a better editor to learn with:
- When editing an element in CM, it is shown and highlighted in the preview
- If you click and element in the preview, the corresponding text is selected in the editor.
- Show errors in HTML / CSS

###

mediator = require "game/mediator"

boxShadow = Modernizr.prefixed "boxShadow"

errors = undefined

$.loadErrors "data/", ["all"], (err) ->
  if err isnt null
    mediator.trigger "alert", err

module.exports = setupCMExtras = (cm) ->
  lastMark = false

  marks = []

  cm.data = {}

  cm.on "cursorActivity", =>
    if lastMark isnt false
      lastMark.data.node.style[boxShadow] = lastMark.data.shadow

    pos = cm.getCursor()
    posmarks = cm.findMarksAt pos
    if posmarks.length isnt 0
      mark = posmarks[posmarks.length - 1]

      if mark.data isnt undefined
        mark.data.shadow = mark.data.node.style[boxShadow]
        if mark.data.shadow is ""
          mark.data.node.style[boxShadow] = "0 0 10px rgba(30, 200, 255, 0.8)"
        else
          mark.data.node.style[boxShadow] += ", 0 0 10px rgba(30, 200, 255, 0.8)"

        showElement mark.data.node

        lastMark = mark

  return process: (html) ->
    parsed = Slowparse.HTML document, html, [TreeInspectors.forbidJS]

    clearMarks()
    linkToPreview parsed.document, marks, cm

    showError cm, parsed.error

    # Remove JS:
    jses = TreeInspectors.findJS parsed.document

    for js in jses
      if js.type is "SCRIPT_ELEMENT"
        js.node.parentNode.removeChild js.node
      if js.type is "EVENT_HANDLER_ATTR" or js.type is "JAVASCRIPT_URL"
        js.node.ownerElement.attributes.removeNamedItem js.node.name

    return parsed

clearMarks = (marks) ->
  if marks isnt undefined
    until (mark = marks.shift()) is undefined
      mark.clear()

showElement = (el) ->
  el.scrollIntoView(true)

showError = (cm, err) ->

  if cm.data.errLine isnt undefined
    cm.removeLineClass cm.data.errLine, "wrap", "slowparse-error"
    cm.data.errWidget.clear()
    cm.data.errLine = cm.data.errWidget = undefined

  if cm.data.tmpMarkers isnt undefined
    clearMarks cm.data.tmpMarkers

  if err isnt null
    error = $("<div></div>").fillError err
    pos = getPositions err, cm

    error.addClass "annotation-widget annotation-error"

    cm.data.errLine = line = pos.start.inner.line

    cm.addLineClass cm.data.errLine, "wrap", "slowparse-error"
    cm.data.errWidget = cm.addLineWidget line, error[0],
      coverGutter: true
      noHScroll: true

    # Highlight links in error messages:
    highlighters = error.find "[data-highlight]"
    highlighters.on "mouseover", ->
      highlight = $ @
      hl = (highlight.data "highlight")
      if typeof hl is "number"
        return

      range = (highlight.data "highlight").split ','
      from = cm.posFromIndex range[0]
      to = cm.posFromIndex range[1]
      marker = cm.markText from, to,
        className: "highlight-error"

      if cm.data.tmpMarkers is undefined
        cm.data.tmpMarkers = [marker]
      else
        cm.data.tmpMarkers.push marker

      highlight.data "cm-error.marker", marker

    highlighters.on "mouseout", ->
      highlight = $ @
      marker = highlight.data "cm-error.marker"
      if marker isnt undefined
        marker.clear()

    highlighters.on "click", ->
      highlight = $ @
      hl = (highlight.data "highlight")
      if typeof hl is "number"
        pos = cm.posFromIndex hl
        cm.setCursor pos
      else
        range = (highlight.data "highlight").split ','
        from = cm.posFromIndex range[0]
        to = cm.posFromIndex range[1]
        cm.setSelection from, to

      cm.focus()

linkToPreview = (node, marks, cm) =>
  if node.parseInfo isnt undefined and node.nodeType is 1

    pos = getPositions node.parseInfo, cm

    mark = cm.markText pos.start.outer, pos.end.outer

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
  p0 = cm.posFromIndex 0

  pos =
    start:
      outer: p0
      inner: p0
    end:
      outer: p0
      inner: p0

  noStart = noEnd = false

  if info.openTag isnt undefined
    pos.start.outer = cm.posFromIndex info.openTag.start
    pos.start.inner = cm.posFromIndex info.openTag.end
  else if info.start isnt undefined
    pos.start.inner = pos.start.outer = cm.posFromIndex info.start
  else
    noStart = true

  if info.closeTag isnt undefined
    pos.end.outer = cm.posFromIndex info.closeTag.end
    pos.end.inner = cm.posFromIndex info.closeTag.start
  else if info.end isnt undefined
    pos.end.inner = pos.end.outer = cm.posFromIndex info.end
  else
    noEnd = true

  if noStart and not noEnd
    pos.start = pos.end
  else if noEnd and not noStart
    pos.end = pos.start

  if noStart and noEnd
    others = ["html", "cssBlock", "cssSelector", "cssProperty", "cssValue", "name"]

    for other in others
      if info[other] isnt undefined
        ref = info[other]
        break

    pos.start.outer = pos.start.inner = cm.posFromIndex ref.start
    pos.end.outer = pos.end.inner = cm.posFromIndex ref.end

  return pos
