/*

Extra bits that make CM a better editor to learn with:
- When editing an element in CM, it is shown and highlighted in the preview
- If you click and element in the preview, the corresponding text is selected in the editor.
- Show errors in HTML / CSS

*/

require! {
  'channels'
  'game/editor/utils'
}

errors = undefined

$.load-errors '/data/', <[all]>, (err) ->
  if err isnt null
    channels.alert.publish msg: err

module.exports = setup-CM-extras = (cm) ->
  last-mark = false
  marks = []
  cm.data = {}

  cm.on "cursorActivity", ~>
    if last-mark isnt false
      last-mark.data.node.class-list.remove 'editing-current-active'

    pos = cm.get-cursor!
    posmarks = cm.find-marks-at pos
    if posmarks.length isnt 0
      mark = posmarks[posmarks.length - 1]

      if mark.data isnt undefined
        mark.data.node.class-list.add 'editing-current-active'
        show-element mark.data.node

        last-mark := mark

  return process: (html) ->
    parsed = Slowparse.HTML document, html, error-detectors: [TreeInspectors.forbid-JS]

    clear-marks!
    link-to-preview parsed.document, marks, cm

    show-error cm, parsed.error

    # Remove JS:
    jses = TreeInspectors.find-JS parsed.document

    for js in jses
      if js.type is "SCRIPT_ELEMENT"
        js.node.parent-node.remove-child js.node
      if js.type is "EVENT_HANDLER_ATTR" or js.type is "JAVASCRIPT_URL"
        js.node.owner-element.attributes.remove-named-item js.node.name

    return parsed

clear-marks = (marks) ->
  if marks isnt undefined
    until (mark = marks.shift!) is undefined
      mark.clear!

show-element = (el) ->
  # el.scrollIntoView(true)

show-error = (cm, err) ->

  if cm.data.err-line isnt undefined
    cm.remove-line-class cm.data.err-line, \wrap, 'slowparse-error'
    cm.data.err-widget.clear!
    cm.data.err-line = cm.data.err-widget = undefined

  if cm.data.tmp-markers isnt undefined
    clear-marks cm.data.tmp-markers

  if err isnt null
    error = $ '<div></div>' .fill-error err
    pos = utils.get-positions err, cm

    error.add-class 'annotation-widget annotation-error'

    cm.data.err-line = line = pos.start.inner.line

    cm.add-line-class cm.data.err-line, \wrap, 'slowparse-error'
    cm.data.err-widget = cm.add-line-widget line, error.0, {+cover-gutter, +no-h-scroll}

    # Highlight links in error messages:
    highlighters = error.find '[data-highlight]'
    highlighters.on \mouseover, ->
      highlight = $ @
      hl = highlight.data \highlight
      if typeof hl is \number
        return

      range = highlight.data \highlight .split ','
      start = cm.pos-from-index range.0
      end = cm.pos-from-index range.1
      marker = cm.mark-text start, end, className: 'highlight-error'

      if cm.data.tmp-markers is undefined
        cm.data.tmp-markers = [marker]
      else
        cm.data.tmp-markers[*] = marker

      highlight.data 'cm-error.marker' marker

    highlighters.on \mouseout, ->
      highlight = $ @
      marker = highlight.data 'cm-error.marker'
      if marker isnt undefined
        marker.clear!

    highlighters.on 'click', ->
      highlight = $ @
      hl = highlight.data \highlight
      if typeof hl is \number
        pos = cm.pos-from-index hl
        cm.set-cursor pos
      else
        range = highlight.data \highlight .split ','
        start = cm.pos-from-index range.0
        end = cm.pos-from-index range.1
        cm.setSelection start, end

      cm.focus!

link-to-preview = (node, marks, cm) ~>
  if node.parse-info isnt undefined and node.node-type is 1

    pos = utils.get-positions node.parse-info, cm

    mark = cm.mark-text pos.start.outer, pos.end.outer

    mark.data = node: node
    marks[*] = mark

    node.add-event-listener \click, (e) ~>
      e.stop-propagation!

      cm.set-selection pos.start.inner, pos.end.inner
      cm.focus!

    , false

  for n in node.child-nodes
    link-to-preview n, marks, cm

