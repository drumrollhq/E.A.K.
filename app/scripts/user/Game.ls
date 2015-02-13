require! {
  'api'
  'user'
}

module.exports = class Game extends Backbone.DeepModel
  @new = ({store, user, options}) ->
    game = new Game!
    game.set-store store
    game.set-user user
    game.setup options

  setup: ({start}) ->
    @store.create game: (@get \game), area: {type: start.0, url: start.1}
      .then ({game, area}) ~>
        @set \id, game.id
        @set \game, game
        @set \area, area
      .then ~> @setup-autosave!
      .then ~> this
      .catch (e) ->
        console.log e
        throw e

  set-store: (store) -> @store = store
  set-user: (user) ->
    user = if typeof user is \object then user.id else user
    @set \game.userId, user

  setup-autosave: ->
    # TODO
