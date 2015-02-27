require! {
  'lib/parse'
}

actors = <[Actor Mover KittenBox Exit]>

module.exports = actors = {[(dasherize name), require "game/actors/#{name}"] for name in actors}

module.exports.from-el = (el, offset, level-store) ->
  $el = $ el
  [actor, ...args] = $el.attr 'data-actor' |> parse.to-list
  unless actors[actor] then throw new Error "No such actor: #{actor}"
  a = actors[actor].from-el $el, args, offset, level-store
  $el.data 'actor', a
  a
