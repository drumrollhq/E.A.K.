export utils = {
  each: (doc, selector, fn) -> for el in doc.query-selector-all selector => fn el
  each-attr: (node, fn) ->
    if node.attributes then for attr in node.attributes => fn attr
    for child in node.child-nodes when child.node-type is node.ELEMENT_NODE
      utils.each-attr child, fn
}

export find-JS = (doc) ->
  js = []
  utils.each doc, 'script', (script) -> js[*] = type: \SCRIPT_ELEMENT, node: script
  utils.each-attr doc, (attr) ->
    if attr.node-name.match /^on/i then js[*] = type: \EVENT_HANDLER_ATTR, node: attr
    if attr.node-value.match /^javascript:/i then js[*] = type: \JAVASCRIPT_URL, node: attr

  js

export forbid-JS = (html, doc) ->
  js = find-JS doc
  unless js.length then return null

  error = JSON.parse JSON.stringify js.0.node.parse-info
  error.type = "#{js.0.type}_NOT_ALLOWED"
  error
