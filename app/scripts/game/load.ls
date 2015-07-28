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
  progress = (progress) ->
    if progress then progress *= 100
    app.loader-view.model.set \progress progress

  bundle = assets.load-bundle "#prefix/areas/#name", progress

  Promise.all [log, bundle]
    .then ([event]) ->
      conf = assets.load-asset "#prefix/areas/#name/area.json"
      conf.name = name
      area = new Area {conf, prefix, name, options, event-id: event.id}
      area.on \done -> logger.stop event.id
      area.on \cleanup -> assets.unload-bundle "#prefix/areas/#name"
      area.load! .then -> area

export minigame = (name, app, options) ->
  log = logger.start \minigame, name: name
  progress = (progress) ->
    if progress then progress *= 100
    app.loader-view.model.set \progress progress

  bundle = assets.load-bundle "minigames/#name", progress
  Promise.all [log, bundle]
    .then ([event]) ->
      MiniGame = require "minigames/#name"
      game = new MiniGame {} <<< options <<< {app}
      game.on \done -> logger.stop event.id
      game.on \cleanup -> assets.unload-bundle "minigames/#name"
      original-save-defaults = game.save-defaults or -> {}
      game.save-defaults = -> {
        type: \minigame
        url: name
        state: original-save-defaults.apply this, arguments or {}
      }
      Promise.resolve game.load!
        .then -> game
