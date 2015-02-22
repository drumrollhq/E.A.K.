require! {
  'api'
  'user'
}

module.exports = class Game extends Backbone.DeepModel
  @new = ({store, user}) ->
    store.create game: {user-id: user.id}
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
      .then ~> this

  find-or-create-stage: (default-data, activate = false) ->
    active-stage = @get \stage or {}
    if active-stage.type is default-data.type and active-stage.url is default-data.url then return Promise.resolve this

    default-data.activate = activate
    @store.find-or-create-stage @id, default-data
      .tap (stage) ~> if activate then @set-active-stage stage, false
