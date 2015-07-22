require! {
  'lib/parse'
}

actors = window.require.list!
  |> filter ( .match /^game\/actors\/[A-Z]/ )
  |> map ( .replace /^game\/actors\// '' )

module.exports = actors = {[(dasherize name), require "game/actors/#{name}"] for name in actors}

module.exports.from-el = (el, offset, level-store, area-view) ->
  $el = $ el
  [actor, ...args] = $el.attr 'data-actor' |> parse.to-list
  unless actors[actor] then throw new Error "No such actor: #{actor}"
  a = actors[actor].from-el $el, args, offset, level-store, area-view
  $el.data 'actor', a
  a

module.exports.register-actor = (ctor) ->
  name = dasherize ctor.display-name
  console.log "[actors] Registered actor #name"
  actors[name] = ctor
