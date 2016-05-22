require! {
  'assets'
  'lib/parse'
}

strip-quotes = (str) -> str.replace /^['"]|['"]$/g, ''

parse-content = (el) ->
  content = window.get-computed-style el .content.trim!
  if content and content isnt \none
    content |> strip-quotes |> parse.to-object
  else
    null

apply-changes = (el, content) ->
  el.add-class content.class if content.class
  attrs = {["#{dasherize key}", value] for key, value of content when (key.index-of \data) is 0}
  el.attr attrs

module.exports = el-modify = ($el) ->
  $el.each (_, el) ->
    $el = $ el
    content = parse-content el
    apply-changes $el, content if content?

    if el.tag-name is 'IMG'
      src = $el.attr 'src'
      unless src.match /_v=|^blob:/
        $el.attr src: assets.load-asset src, \url

    el-modify $el.children!
