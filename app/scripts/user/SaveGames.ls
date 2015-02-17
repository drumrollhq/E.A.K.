require! {
  'user/SaveGame'
  'user'
}

module.exports = class SaveGames extends Backbone.Collection
  model: SaveGame

  latest: -> first @recent!
  recent: (limit = 10, offset = 0) ->
    @models
    |> sort-by ( .updated! )
    |> reverse
    |> drop offset
    |> take limit

  delete: (id) ->
    game = @get id
    game.delete!
      .then ~> @remove game

