require! {
  'game/Level'
  'game/Bar'
  'game/Background'
  'game/mediator'
}

module.exports = class Game extends Backbone.Model
  initialize: (load) ->
    if load then @load! else @save!

    @on \change @save

    background = new Background!

    @$level-title = $ \.levelname
    @$level-no = @$level-title.find \span
    @$level-name = @$level-title.find \h4

    bar-view = new Bar el: $ \#bar

  defaults: level: 0

  start-level: (n) ~>
    unless mediator.LevelStore[n]?
      console.log "Cannot find level #n" mediator.LevelStore
      mediator.trigger \alert "That's it! I haven't written any more levels yet!"
      return false

    level = mediator.LevelStore[n]
    @$level-no.text n + 1

    @$level-name.text if level.config?.name? then level.config.name or ''

    <~ $.hide-dialogues

    new Level level

    mediator.once \levelout, ~>
      l = (@get \level) + 1
      @set \level, l
      @start-level l

  save: ~> @attributes |> _.clone |> JSON.stringify |> local-storage.set-item Game::savefile, _

  load: ~> Game::savefile |> local-storage.get-item |> JSON.parse |> @set

  savefile: \kittenquest-savegame
