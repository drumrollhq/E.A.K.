require! {
  'game/CutScene'
  'logger'
}
first-path = window.location.pathname |> split '/' |> reject empty |> first
if first-path in window.LANGUAGES
  prefix = "/#first-path"
else prefix = ''

export cutscene = (name, app) ->
  log = logger.start 'cutscene' name: name

  cutscene = new CutScene {name: "#prefix/cutscenes/#name"}
  Promise.all [log, cutscene.load!]
    .then ([event]) ->
      cutscene
        ..on 'skip' -> logger.log 'skip'
        ..on 'finish' -> logger.stop event.id

      cutscene

