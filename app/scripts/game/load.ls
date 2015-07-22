require! {
  'assets'
  'game/CutScene'
  'game/area/Area'
  'lib/parse'
  'logger'
}
first-path = window.location.pathname |> split '/' |> reject empty |> first
if first-path in window.LANGUAGES
  prefix = "/#first-path"
else prefix = ''

export cutscene = (name, app, options) ->
  log = logger.start \cutscene name: name

  cutscene = new CutScene {url: "#prefix/cutscenes/#name", name}
  Promise.all [log, cutscene.load!]
    .then ([event]) ->
      cutscene
        ..on \skip -> logger.log \skip
        ..on \finish -> logger.stop event.id

      cutscene

export area = (name, app, options) ->
  log = logger.start \level {level: name}
  bundle = assets.load-bundle "#prefix/areas/#name"
  Promise.all [log, bundle]
    .then ([event]) ->
      conf = assets.load-asset "#prefix/areas/#name/area.json"
      conf.name = name
      area = new Area {conf, prefix, name, options, event-id: event.id}
      area.on \done -> logger.stop event.id
      area.load! .then -> area
