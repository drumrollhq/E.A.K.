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

export cutscene = (name, app) ->
  log = logger.start \cutscene name: name

  cutscene = new CutScene {name: "#prefix/cutscenes/#name"}
  Promise.all [log, cutscene.load!]
    .then ([event]) ->
      cutscene
        ..on \skip -> logger.log \skip
        ..on \finish -> logger.stop event.id

      cutscene

export area = (name, app) ->
  {url, player-coords} = parse-url name
  logger.start \level {level: url}
    .then (event) -> Promise.all [event, $.get-JSON "#{prefix}/areas/#{url}/area.json?_v=#{EAKVERSION}"]
    .spread (event, conf) ->
      area = new Area {conf, prefix, player-coords, url, event-id: event.id}
      area.on \done -> logger.stop event.id
      area.load!

parse-url = (url) ->
  parts = url.split '#'
  url = parts.0
  player-coords = if parts.1 then parse.to-coordinates parts.1, ',' else null
  {url, player-coords}
