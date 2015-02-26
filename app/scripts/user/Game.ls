require! {
  'api'
  'user'
}

module.exports = class Game extends Backbone.DeepModel
  @new = ({store, user}) ->
    store.create game: {user-id: user?.id}
      .then ({game}) -> new Game {id: game.id, game}
      .tap (game) ->
        game.set-store store
        game.setup-autosave!

  @load = ({store, id, user}) ->
    store.get id
      .then (game) -> new Game id: game.id, game: game, stage: game.active-stage
      .tap (game) ->
        game.set-store store
        game.setup-autosave!

  set-store: (store) -> @store = store
  set-user: (user) ->
    user = if typeof user is \object then user.id else user
    @set \game.userId, user

  setup-autosave: ->
    @on \all -> console.log 'Game:', arguments
    # TODO

  reset: (key, value) ->
    @unset key
    @set key, value

  active-stage: ->
    @get \stage

  set-active-stage: (stage, persist = true) ->
    Promise.resolve (if persist then @store.patch @id, active-stage: stage.id)
      .then ~>
        @set 'game.activeStage': stage.id
        @reset 'stage' stage
        if stage.levels
          @reset 'levels' _.index-by stage.levels, 'id'
      .then ~> this

  find-or-create-stage: (default-data, activate = false) ->
    active-stage = @get \stage or {}

    default-data.activate = activate
    @store.find-or-create-stage @id, default-data
      .tap (stage) ~> if activate then @set-active-stage stage, false

  level-by-url: (url) ->
    level = @get \levels
      |> values
      |> filter ( .url is url )
      |> first

  scope-level: (url) ->
    level = @level-by-url url
    unless level then throw new Error "No level with url #url"

    root-path = "levels.#{level.id}"
    scope-path = (sub-path) -> if sub-path then "#root-path.#sub-path" else root-path

    lvl = {
      game: this
      level: level
      id: level.id
      url: url
      get: (sub-path) ~>
        console.log 'get', sub-path, scope-path sub-path
        @get scope-path sub-path

      set: (key, value, options) ~>
        | typeof! key is \Object => @set {"#{root-path}": key}, value
        | typeof! key is \String => @set (scope-path key), value, options
        | otherwise => throw new TypeError "Bad key type: #{typeof! key}"

      patch-state: (patch, value) ~>
        if typeof patch is \string then patch = {"#patch": value}
        lvl.set state: patch
        @store.patch-level-state @id, level.id, patch

      save-kitten: (kitten) ~> @save-kitten level.id, kitten
    }

  save-kitten: (level-id, kitten) ~>
    @set {
      "levels.#{level-id}.state.kittens.#{kitten}": Date.now!
      'game.state.kittenCount': 1 + (@get \game.state.kittenCount or 0)
    }, silent: true

    @store.save-kitten @id, level-id, kitten

  patch-stage-state: (patch, value) ->
    if typeof patch is \string then patch = {"#patch": value}
    @set \stage.state patch
    @store.patch-stage-state @id, (@get \stage.id), patch
