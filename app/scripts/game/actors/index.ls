require! {
  'lib/parse'
}

actors = <[Actor Mover KittenBox Exit Spike Portal Particles FadingPanel]>

module.exports = actors = {[(dasherize name), require "game/actors/#{name}"] for name in actors}

module.exports.from-el = (el, offset, level-store, area-view) ->
  $el = $ el
  [actor, ...args] = $el.attr 'data-actor' |> parse.to-list
  console.log 'find' actor, 'in', (keys actors)
  unless actors[actor] then throw new Error "No such actor: #{actor}"
  a = actors[actor].from-el $el, args, offset, level-store, area-view
  $el.data 'actor', a
  a
