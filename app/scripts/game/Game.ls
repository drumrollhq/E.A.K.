require! {
  'channels'
  'game/CutScene'
  'game/Events'
  'game/Level'
  'logger'
  'ui/Bar'
}

first-path = window.location.pathname |> split '/' |> reject empty |> first
if first-path in window.LANGUAGES
  prefix = "/#first-path"
else prefix = ''

module.exports = class Game extends Backbone.Model
  initialize: (load, @logger-parent) ->
    if load then @load! else @save!

    @on \change @save

    @$level-title = $ \.levelname
    @$level-no = @$level-title.find \span
    @$level-name = @$level-title.find \h4

    bar-view = new Bar el: $ \#bar

    channels.stage.filter ( .type is 'level' ) .subscribe ({url}) ~> @start-level url
    channels.stage.filter ( .type is 'cutscene' ) .subscribe ({url}) ~> @start-cutscene url

  defaults: level: '/levels/index.html'

  start-level: (level-url) ~>
    event <~ logger.start 'level', {level: level-url, parent: @logger-parent}
    console.log {level-url}
    l = prefix + level-url + "?#{Date.now!}"
    logger.set-default-parent event.id
    level-source <~ $.get l, _
    parsed = Slowparse.HTML document, level-source, [TreeInspectors.forbidJS]

    if parsed.error isnt null
      channels.alert.publish msg: 'There are errors in that level!'
      return

    for node in parsed.document.child-nodes
      if typeof! node is 'HTMLHtmlElement' then $level = $ node

    @$level-name.text ($level.find 'title' .text! or '')

    <~ $.hide-dialogues

    level = new Level $level
    level.event-id = event.id
    level.on 'done' -> event.stop!

  start-cutscene: (name) ~>
    cs = new CutScene {name}
    cs.$el.append-to document.body
    cs.render!
    event <~ logger.start 'cutscene', {name: name, parent: @logger-parent}
    cs.on 'finish' -> event.stop!
    cs.on 'skip' -> logger.log 'skip' {parent: event.id}

  save: ~> @attributes |> _.clone |> JSON.stringify |> local-storage.set-item Game::savefile, _

  load: ~> Game::savefile |> local-storage.get-item |> JSON.parse |> @set

  savefile: \kittenquest-savegame
