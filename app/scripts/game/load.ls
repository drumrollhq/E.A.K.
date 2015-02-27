require! {
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
  # <~ Promise.delay 500 .then # Delay to prevent nasty lockups
  logger.start \level {level: name}
    .then (event) -> Promise.all [event, $.get-JSON "#{prefix}/areas/#{name}/area.json?_v=#{EAKVERSION}"]
    .spread (event, conf) ->
      area = new Area {conf, prefix, name, options, event-id: event.id}
      area.on \done -> logger.stop event.id
      area.load!
