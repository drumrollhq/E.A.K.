require! {
  'lib/parse'
}

actors = <[Actor Mover]>

module.exports = actors = {[name.to-lower-case!, require "game/actors/#{name}"] for name in actors}

module.exports.from-el = (el, offset) ->
  $el = $ el
  [actor, ...args] = $el.attr 'data-actor' |> parse.to-list
  actors[actor].from-el $el, args, offset
