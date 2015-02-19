require! {
  'api'
  'user'
}

module.exports = class Game extends Backbone.DeepModel
  @new = ({store, user, options}) ->
    start = options.[]start
    store.create game: {user-id: user.id}, area: {type: start.0, url: start.1}
      .then ({game, area}) -> new Game {id: game.id, game, area}
      .tap (game) ->
        game.set-store store
        game.setup-autosave!

  @load = ({store, id, user}) ->
    store.get id
      .then (game) -> new Game id: game.id, game: game, area: game.active-area
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

  active-area: ->
    @get \area

  set-active-area: (area, persist = true) ->
    Promise.resolve (if persist then @store.patch @id, active-area: area.id)
      .then ~>
        @set 'game.activeArea': area.id
        @reset 'area' area
      .then ~> this

  find-or-create-area: (type, url, activate = false) ->
    active-area = @get \area
    if active-area.type is type and active-area.url is url then return Promise.resolve this
    @store.find-or-create-area @id, {type, url, activate}
      .tap (area) ~> if activate then @set-active-area area, false
