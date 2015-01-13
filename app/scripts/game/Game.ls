require! {
  'game/CutScene'
  'game/Events'
  'game/area/Area'
  'game/pauser'
  'lib/channels'
  'lib/parse'
  'logger'
  'translations'
}

first-path = window.location.pathname |> split '/' |> reject empty |> first
if first-path in window.LANGUAGES
  prefix = "/#first-path"
else prefix = ''

module.exports = class Game extends Backbone.Model
  initialize: (load) ->
    if load then @load! else @save!

    @on \change @save

    @$level-title = $ \.levelname
    @$level-no = @$level-title.find \span
    @$level-name = @$level-title.find \h4

    channels.stage.filter ( .type in <[cutscene area]> ) .subscribe ({type, url}) ~> @start type, url

  defaults: level: '/levels/index.html'

  start: (type, url) ->
    if @current isnt url
      @current = url
      switch type
      | \cutscene => @start-cutscene url
      | \area => @start-area url

  start-cutscene: (name) ~>
    cs = new CutScene {name: "#prefix/cutscenes/#name"}
    cs.$el.append-to document.body
    cs.render!
    event <~ logger.start 'cutscene', {name: name}
    cs.on 'finish' -> logger.stop event.id
    cs.on 'skip' -> logger.log 'skip'

  start-area: (url) ~>
    {url, player-coords} = parse-url url
    event <~ logger.start 'level', {level: url}
    l = prefix + url + "?_v=#{EAKVERSION}"
    conf <~ $.get-JSON l
    area = new Area conf: conf, event-id: event.id, prefix: prefix, player-coords: player-coords
    area.on 'done' -> logger.stop event.id
    area.start!

  save: ~> @attributes |> _.clone |> JSON.stringify |> local-storage.set-item Game::savefile, _

  load: ~> Game::savefile |> local-storage.get-item |> JSON.parse |> @set

  savefile: \kittenquest-savegame

parse-url = (url) ->
  parts = url.split '#'
  url = parts.0
  player-coords = if parts.1? then parse.to-coordinates parts.1, ',' else null
  {url, player-coords}
