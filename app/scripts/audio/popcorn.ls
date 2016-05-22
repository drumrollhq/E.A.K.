require! {
  'audio/context'
  'assets'
}

module.exports = (root, name) ->
  path = if name then "#root/#name" else root
  url = assets.load-asset "#{path}.#{context.format}", \url
  Popcorn new Audio url
